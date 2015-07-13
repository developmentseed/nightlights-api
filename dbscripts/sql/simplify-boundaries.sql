--- Topologically-intact Simplification

--- From http://strk.keybit.net/blog/2012/04/13/simplifying-a-map-layer-using-postgis-topology/

CREATE OR REPLACE FUNCTION SimplifyEdgeGeom(atopo varchar, anedge int, maxtolerance float8)
RETURNS float8 AS $$
DECLARE
  tol float8;
  sql varchar;
BEGIN
  tol := maxtolerance;
  LOOP
    sql := 'SELECT topology.ST_ChangeEdgeGeom(' || quote_literal(atopo) || ', ' || anedge
      || ', ST_Simplify(geom, ' || tol || ')) FROM '
      || quote_ident(atopo) || '.edge WHERE edge_id = ' || anedge;
    BEGIN
      RAISE DEBUG 'Running %', sql;
      EXECUTE sql;
      RETURN tol;
    EXCEPTION
     WHEN OTHERS THEN
      RAISE WARNING 'Simplification of edge % with tolerance % failed: %', anedge, tol, SQLERRM;
      tol := round( (tol/2.0) * 1e8 ) / 1e8; -- round to get to zero quicker
      IF tol = 0 THEN RAISE EXCEPTION '%', SQLERRM; END IF;
    END;
  END LOOP;
END
$$ LANGUAGE 'plpgsql' STABLE STRICT;

--- Districts

-- Create a topology
select topology.droptopogeometrycolumn('public', 'districts_boundaries', 'topogeom');
select topology.DropTopology('districts_topo');
select topology.CreateTopology('districts_topo', find_srid('public', 'districts_boundaries', 'geom'));
-- Add a layer
select topology.addtopogeometrycolumn('districts_topo', 'public', 'districts_boundaries', 'topogeom', 'MULTIPOLYGON');
-- Populate the layer and the topology: this step takes a while.
UPDATE districts_boundaries SET topogeom = topology.toTopoGeom(geom, 'districts_topo', 1);
SELECT SimplifyEdgeGeom('districts_topo', edge_id, 0.01) FROM districts_topo.edge;
-- Convert the TopoGeometries to Geometries for visualization
ALTER TABLE districts_boundaries DROP COLUMN geom_simplified;
ALTER TABLE districts_boundaries ADD geom_simplified GEOMETRY;
UPDATE districts_boundaries SET geom_simplified = topogeom::geometry;

--- States
-- Create a topology
select topology.droptopogeometrycolumn('public', 'states_boundaries', 'topogeom');
select topology.DropTopology('states_topo');
select topology.CreateTopology('states_topo', find_srid('public', 'states_boundaries', 'geom'));
-- Add a layer
select topology.addtopogeometrycolumn('states_topo', 'public', 'states_boundaries', 'topogeom', 'MULTIPOLYGON');
-- Populate the layer and the topology: this step takes a while.
UPDATE states_boundaries SET topogeom = topology.toTopoGeom(geom, 'states_topo', 1);
SELECT SimplifyEdgeGeom('states_topo', edge_id, 0.05) FROM states_topo.edge;
-- Convert the TopoGeometries to Geometries for visualization
ALTER TABLE states_boundaries DROP COLUMN geom_simplified;
ALTER TABLE states_boundaries ADD geom_simplified GEOMETRY;
UPDATE states_boundaries SET geom_simplified = topogeom::geometry;

