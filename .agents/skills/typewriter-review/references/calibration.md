# Calibration

Keep 10 real Typewriter diffs with seeded or known problems, each labelled by Gabber with the expected items and whether each is a plan flaw or an execution flaw. A skill change is accepted only if, over the set, it finds at least as many expected findings and raises no more false ones than before. Results live in the project at `xtask/src/review/calibration/results.md`.

Run the set only when this skill or its references change, so it costs nothing per pull request.
