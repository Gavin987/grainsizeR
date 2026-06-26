# Source boundaries

grainsizeR is an R-native sediment grain-size analysis package. It provides
documented workflows for grain-size summaries, plotting, USDA major texture
classification, GRADISTAT-style texture classification, and GRADISTAT-style
sediment-name composition.

## GRADISTAT

GRADISTAT is used as a source and replacement target for functional behavior.
The package does not bundle a GRADISTAT workbook, copied VBA code, workbook
chart objects, or Excel printout layouts. GRADISTAT-style decisions are
implemented as independently written R rules and tests.
VBA source code was not copied into grainsizeR.

## G2Sd

G2Sd is referenced as a workflow replacement target. The package does not copy G2Sd source code or internal implementation files.

## soiltexture

The package does not depend on `soiltexture`, does not call `soiltexture` at
runtime, and does not copy `soiltexture` source code, class tables, polygon
tables, topology, or coordinate data.

## Texture polygons

Built-in official texture polygon datasets are not bundled. Users can supply
their own polygons through the public texture polygon workflow.

## Known limits

USDA major 12-class texture classification is implemented. USDA sand-size
modifier subclasses, AASHTO, USCS, and additional national texture systems are
outside the current public scope unless they are added in a future scoped
change.
