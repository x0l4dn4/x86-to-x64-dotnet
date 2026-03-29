param([string]$Path = ".")

gci $Path -r -dir | ? { $_.Name -in "bin","obj" } | ri -r -fo  # You may have other aliases I just write them cuz who likes to write more???

# gci -Path $Path -Recurse -Directory | Where-Object { $_.Name -in @("bin", "obj") } | ri -Recurse -Force
