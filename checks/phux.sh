hdr "personal terminal tools"
if phux config check >/dev/null 2>&1; then ok "Phux layered configuration valid"
else fail "Phux config invalid — phux config check"; fi
if phig config check >/dev/null 2>&1; then ok "Phig preferences valid"
else fail "Phig config invalid — phig config check"; fi
