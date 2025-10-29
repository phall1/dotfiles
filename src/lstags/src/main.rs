use anyhow::{Context, Result};
use clap::{CommandFactory, Parser, Subcommand};
use serde_json::json;
use std::collections::BTreeMap;
use std::fs;
use std::io::{self, IsTerminal, Write};
use std::path::{Path, PathBuf};

mod tags;
use tags::Tag;

#[derive(Parser)]
#[command(name = "lstags", version, about = "ls but it shows your Finder tags")]
#[command(args_conflicts_with_subcommands = true)]
struct Cli {
    /// Files to inspect, or directories to list
    paths: Vec<PathBuf>,

    /// Only show entries tagged with this (repeatable; AND by default)
    #[arg(short = 't', long = "tag", value_name = "TAG")]
    tag: Vec<String>,

    /// Use OR semantics for --tag filters instead of AND
    #[arg(long)]
    any: bool,

    /// Include hidden files when listing directories
    #[arg(short = 'a', long)]
    all: bool,

    /// Print NUL-separated paths instead of formatted output (for xargs -0)
    #[arg(short = '0', long)]
    null: bool,

    /// Emit JSON instead of pretty output
    #[arg(long)]
    json: bool,

    /// Disable colored output (NO_COLOR env var also honored)
    #[arg(long)]
    no_color: bool,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Subcommand)]
enum Command {
    /// Add tags to a path
    Add { path: PathBuf, tags: Vec<String> },
    /// Remove tags from a path
    Rm { path: PathBuf, tags: Vec<String> },
    /// Count tag occurrences across a directory's contents
    Inventory { dir: PathBuf },
}

fn main() {
    if let Err(e) = run() {
        eprintln!("lstags: {}", e);
        for cause in e.chain().skip(1) {
            eprintln!("  caused by: {}", cause);
        }
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Some(Command::Add { path, tags }) => {
            let n = tags::add(path, tags)?;
            if cli.json {
                println!("{}", json!({"path": path.to_string_lossy(), "added": n}));
            } else {
                println!("added {} tag(s) to {}", n, path.display());
            }
        }
        Some(Command::Rm { path, tags }) => {
            let n = tags::remove(path, tags)?;
            if cli.json {
                println!("{}", json!({"path": path.to_string_lossy(), "removed": n}));
            } else {
                println!("removed {} tag(s) from {}", n, path.display());
            }
        }
        Some(Command::Inventory { dir }) => {
            inventory(dir, cli.json)?;
        }
        None => {
            if cli.paths.is_empty() {
                Cli::command().print_help()?;
                println!();
                return Ok(());
            }
            show(&cli)?;
        }
    }
    Ok(())
}

enum Row {
    Header(String),
    Entry(String, Vec<Tag>),
    Blank,
}

fn show(cli: &Cli) -> Result<()> {
    let color_on = color_enabled(cli.no_color);
    let multi = cli.paths.len() > 1;
    let mut rows: Vec<Row> = Vec::new();

    for (i, p) in cli.paths.iter().enumerate() {
        let meta = fs::symlink_metadata(p)
            .with_context(|| format!("statting {}", p.display()))?;

        if meta.is_dir() {
            if multi {
                if i > 0 {
                    rows.push(Row::Blank);
                }
                rows.push(Row::Header(format!("{}:", p.display())));
            }
            let mut entries: Vec<_> = fs::read_dir(p)
                .with_context(|| format!("reading {}", p.display()))?
                .collect::<Result<Vec<_>, _>>()?;
            entries.sort_by_key(|e| e.file_name());

            for entry in entries {
                let name = entry.file_name().to_string_lossy().into_owned();
                if !cli.all && name.starts_with('.') {
                    continue;
                }
                let etags = tags::read(&entry.path())?;
                if !matches_filter(&etags, &cli.tag, cli.any) {
                    continue;
                }
                let ft = entry.file_type()?;
                let display = if ft.is_symlink() {
                    format!("{}@", name)
                } else if ft.is_dir() {
                    format!("{}/", name)
                } else {
                    name
                };
                rows.push(Row::Entry(display, etags));
            }
        } else {
            let etags = tags::read(p)?;
            if !matches_filter(&etags, &cli.tag, cli.any) {
                continue;
            }
            rows.push(Row::Entry(p.display().to_string(), etags));
        }
    }

    if cli.json {
        let arr: Vec<_> = rows
            .iter()
            .filter_map(|r| match r {
                Row::Entry(name, tags) => Some(json!({
                    "path": name,
                    "tags": tags.iter().map(|t| json!({
                        "name": t.name,
                        "color": t.color
                    })).collect::<Vec<_>>(),
                })),
                _ => None,
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&arr)?);
        return Ok(());
    }

    if cli.null {
        let mut out = io::stdout().lock();
        for r in &rows {
            if let Row::Entry(name, _) = r {
                out.write_all(name.as_bytes())?;
                out.write_all(b"\0")?;
            }
        }
        return Ok(());
    }

    let max_name = rows
        .iter()
        .filter_map(|r| match r {
            Row::Entry(name, _) => Some(name.chars().count()),
            _ => None,
        })
        .max()
        .unwrap_or(0);

    let mut out = io::stdout().lock();
    for r in &rows {
        match r {
            Row::Header(s) => writeln!(out, "{}", s)?,
            Row::Blank => writeln!(out)?,
            Row::Entry(name, tags) => {
                let pad = max_name.saturating_sub(name.chars().count());
                write!(out, "{}{}  ", name, " ".repeat(pad))?;
                for (i, t) in tags.iter().enumerate() {
                    if i > 0 {
                        write!(out, " ")?;
                    }
                    write!(out, "{}", render_tag(t, color_on))?;
                }
                writeln!(out)?;
            }
        }
    }
    Ok(())
}

fn inventory(dir: &Path, json_out: bool) -> Result<()> {
    let mut counts: BTreeMap<String, usize> = BTreeMap::new();
    let entries: Vec<_> = fs::read_dir(dir)
        .with_context(|| format!("reading {}", dir.display()))?
        .collect::<Result<Vec<_>, _>>()?;

    for entry in entries {
        for t in tags::read(&entry.path())? {
            *counts.entry(t.name).or_insert(0) += 1;
        }
    }

    let mut sorted: Vec<_> = counts.into_iter().collect();
    sorted.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(&b.0)));

    if json_out {
        let arr: Vec<_> = sorted
            .iter()
            .map(|(n, c)| json!({"tag": n, "count": c}))
            .collect();
        println!("{}", serde_json::to_string_pretty(&arr)?);
    } else {
        let color_on = color_enabled(false);
        for (name, count) in &sorted {
            let t = Tag::new(name.clone(), 0);
            println!("{:>4}  {}", count, render_tag(&t, color_on));
        }
    }
    Ok(())
}

fn matches_filter(tags: &[Tag], filters: &[String], any: bool) -> bool {
    if filters.is_empty() {
        return true;
    }
    let has = |name: &str| tags.iter().any(|t| t.name.eq_ignore_ascii_case(name));
    if any {
        filters.iter().any(|f| has(f))
    } else {
        filters.iter().all(|f| has(f))
    }
}

fn color_enabled(no_color_flag: bool) -> bool {
    !no_color_flag
        && std::env::var_os("NO_COLOR").is_none()
        && io::stdout().is_terminal()
}

const FINDER_ANSI: [u8; 8] = [
    8, 244, 114, 140, 75, 222, 174, 215,
];

const CUSTOM_PALETTE: [u8; 14] = [
    30, 36, 42, 99, 105, 135, 165, 171, 196, 202, 208, 220, 84, 117,
];

fn ansi_for(tag: &Tag) -> u8 {
    if tag.color > 0 && tag.color <= 7 {
        FINDER_ANSI[tag.color as usize]
    } else {
        let mut h: u32 = 5381;
        for b in tag.name.to_ascii_lowercase().bytes() {
            h = h.wrapping_mul(33).wrapping_add(b as u32);
        }
        CUSTOM_PALETTE[(h as usize) % CUSTOM_PALETTE.len()]
    }
}

fn render_tag(tag: &Tag, color_on: bool) -> String {
    if color_on {
        format!("\x1b[38;5;{}m#{}\x1b[0m", ansi_for(tag), tag.name)
    } else {
        format!("#{}", tag.name)
    }
}
