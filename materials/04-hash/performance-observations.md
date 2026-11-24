# Open Dev File Hash · Performance observations

Machine / Flutter / mode:
File SHA-256:

| Build | File | Dart used peak / idle | External peak / idle | RSS peak / idle | Longest observed UI / raster frame | Result |
|---|---|---|---|---|---|---|
| Baseline | 64 MiB | | | | | |
| Baseline | 128 MiB | | | | | |
| Streaming | 64 MiB | | | | | |
| Streaming | 128 MiB | | | | | |

CPU profiler workload: Dart CLI / mode / file:
Most visible call tree entry (whole):
Most visible call tree entry (stream):
What the measurements show:
Sampling limitations and anything to rerun:
