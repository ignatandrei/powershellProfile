Inspired by utilities from

https://evanhahn.com/scripts-i-wrote-that-i-use-all-the-time/

## How these files are used

All `.ps1` files in this folder are concatenated by CI (and by `scripts/concat-pws.ps1` locally) into a single unified PowerShell profile at `dist/pws-profile.ps1`.

- Concatenation order: alphabetical by filename.
- Keep each file self-contained and idempotent (safe to re-run); avoid relying on implicit state from another file unless alphabetical order guarantees it.
- Non-script files (like this Readme) are ignored.

Contributions: add new utilities as separate `.ps1` files. The CI will pick them up automatically.

