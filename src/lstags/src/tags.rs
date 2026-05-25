use anyhow::{Context, Result, bail};
use plist::Value;
use std::path::Path;

pub const XATTR_NAME: &str = "com.apple.metadata:_kMDItemUserTags";

#[derive(Debug, Clone)]
pub struct Tag {
    pub name: String,
    pub color: u8,
}

impl Tag {
    pub fn new(name: impl Into<String>, color: u8) -> Self {
        Self { name: name.into(), color }
    }

    fn from_encoded(s: &str) -> Self {
        match s.split_once('\n') {
            Some((name, idx)) => Self {
                name: name.to_string(),
                color: idx.parse().unwrap_or(0),
            },
            None => Self { name: s.to_string(), color: 0 },
        }
    }

    fn to_encoded(&self) -> String {
        if self.color == 0 {
            self.name.clone()
        } else {
            format!("{}\n{}", self.name, self.color)
        }
    }
}

pub fn read(path: &Path) -> Result<Vec<Tag>> {
    let bytes = match xattr::get(path, XATTR_NAME)
        .with_context(|| format!("reading xattrs of {}", path.display()))?
    {
        Some(b) if !b.is_empty() => b,
        _ => return Ok(vec![]),
    };

    let value: Value = plist::from_bytes(&bytes)
        .with_context(|| format!("parsing tag bplist for {}", path.display()))?;

    let arr = value
        .as_array()
        .with_context(|| format!("tag bplist is not an array for {}", path.display()))?;

    Ok(arr.iter().filter_map(|v| v.as_string().map(Tag::from_encoded)).collect())
}

pub fn write(path: &Path, tags: &[Tag]) -> Result<()> {
    if tags.is_empty() {
        match xattr::remove(path, XATTR_NAME) {
            Ok(()) => Ok(()),
            // ENOATTR (93 on macOS) means there was nothing to remove.
            Err(e) if e.raw_os_error() == Some(93) => Ok(()),
            Err(e) => Err(e).with_context(|| format!("removing xattr from {}", path.display())),
        }
    } else {
        let encoded: Vec<Value> = tags.iter().map(|t| Value::String(t.to_encoded())).collect();
        let mut buf = Vec::new();
        plist::to_writer_binary(&mut buf, &Value::Array(encoded))
            .context("encoding tag bplist")?;
        xattr::set(path, XATTR_NAME, &buf)
            .with_context(|| format!("writing xattr to {}", path.display()))
    }
}

pub fn add(path: &Path, names: &[String]) -> Result<usize> {
    let mut tags = read(path)?;
    let mut added = 0;
    for name in names {
        validate(name)?;
        if !tags.iter().any(|t| t.name.eq_ignore_ascii_case(name)) {
            tags.push(Tag::new(name, 0));
            added += 1;
        }
    }
    if added > 0 {
        write(path, &tags)?;
    }
    Ok(added)
}

pub fn remove(path: &Path, names: &[String]) -> Result<usize> {
    let mut tags = read(path)?;
    let before = tags.len();
    tags.retain(|t| !names.iter().any(|n| t.name.eq_ignore_ascii_case(n)));
    let removed = before - tags.len();
    if removed > 0 {
        write(path, &tags)?;
    }
    Ok(removed)
}

pub fn validate(name: &str) -> Result<()> {
    if name.is_empty() {
        bail!("tag cannot be empty");
    }
    if name.contains('\n') {
        bail!("tag cannot contain newline: {:?}", name);
    }
    if name.chars().any(|c| c.is_ascii_control()) {
        bail!("tag cannot contain control characters: {:?}", name);
    }
    Ok(())
}
