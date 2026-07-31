# Rig diagnostics contract

The server editor exposes rig data next to the generated result.

Required frame fields:

- canonical node hierarchy and semantic render slots;
- node parent and attachment identifier;
- local transform applied for the current phase;
- resolved node bounds;
- overscan canvas dimensions;
- shared clip camera;
- motion profile and emitted events;
- hair, jewelry, companion, cape and wing segment data.

The editor diagnostic panel must display the selected node, its parent, anchor,
local transform, bounds and direct children. Debug drawing may show anchors,
pivots, node bounds, overscan and the final 48 x 48 viewport.

The production image remains unchanged when diagnostics are enabled. Diagnostic
values are metadata produced from the same rig state used for composition; the
frontend must not reconstruct the hierarchy from layer names.
