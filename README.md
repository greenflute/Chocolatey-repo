# Chocolatey repository

Personal Chocolatey repository for Tokcos and other useful Windows software.

## Build a package

```powershell
cd <package-directory>
choco pack
```

## Local test

```powershell
choco install <package-id> --source . --yes
```

Tokcos package IDs:

```text
tokcos-cli
tokcos-work
```
