# Patch smells

For the flagged hunks, answer each with file:line and plan flaw or execution flaw, or "not present".

1. A new flag or boolean parameter on an existing function. (detector: branch-growth; usually plan: the model lacks a case)
2. A new branch in an existing function for one caller's case. (detector: branch-growth; usually plan)
3. A string, map or untyped value standing in for an ID, state or variant. (usually execution)
4. A new type or function beside an existing one that does nearly the same thing. (tools: similar; usually plan)
5. A superseded path left in place instead of deleted in the same change. (tools: callers --base; plan or execution)
6. A fix at the symptom instead of the layer that owns the invariant. (usually plan)
7. A null check, default, or catch that hides a defect. (detector: rules; usually execution)
8. A test changed to match new output without a requirement asking for it. (tests: weakened, rewritten; execution)
9. A wrapper or layer that owns no policy. (tools: forwards; usually plan)
10. A heuristic growing a list of exceptions where a structural model belongs. (usually plan)
11. A test that restates what the code does instead of checking the requirement's outcome. (execution)
12. Code worked around a neighbour instead of fixing it. (tools: neighbours, history; plan)
