import h3
from typing import Optional, List, Set, Tuple
from config import H3_RESOLUTION


class H3GeoProcessor:
    """Handles H3 geometric operations for trails and claims"""
    
    def __init__(self, resolution: int = H3_RESOLUTION):
        self.resolution = resolution
    
    def snap_to_h3(self, lat: float, lng: float) -> str:
        """Convert lat/lng to H3 cell at configured resolution"""
        return h3.latlng_to_cell(lat, lng, self.resolution)
    
    def get_h3_neighbors(self, h3_index: str) -> Set[str]:
        """Get neighboring H3 cells"""
        return set(h3.grid_disk(h3_index, 1))
    
    def cells_to_polygon(self, h3_cells: Set[str]) -> List[Tuple[float, float]]:
        """Convert H3 cells to polygon boundary"""
        if not h3_cells:
            return []
        
        # Get boundary cells
        boundary_cells = set()
        for cell in h3_cells:
            neighbors = self.get_h3_neighbors(cell)
            # Cell is on boundary if it has neighbors not in the set
            if not neighbors.issubset(h3_cells):
                boundary_cells.add(cell)
        
        # Convert to lat/lng coordinates
        coords = []
        for cell in boundary_cells:
            lat, lng = h3.cell_to_latlng(cell)
            coords.append((lat, lng))
        
        return coords
    
    def calculate_area_m2(self, h3_cells: Set[str]) -> float:
        """Calculate area in square meters for H3 cells"""
        total_area = 0.0
        for cell in h3_cells:
            # Get cell area in square meters
            cell_area = h3.cell_area(cell, unit='m^2')
            total_area += cell_area
        return total_area
    
    def detect_loop_closure(self, trail_cells: List[str], claimed_territory: Set[str]) -> Optional[Set[str]]:
        """Detect if trail forms a loop with existing territory and return enclosed area"""
        if len(trail_cells) < 3:
            return None
        
        trail_set = set(trail_cells)
        
        # Check if trail intersects with claimed territory
        intersection = trail_set.intersection(claimed_territory)
        if not intersection:
            return None
        
        # Find enclosed area using flood fill from trail boundary
        # This is a simplified version - in production would use proper polygon algorithms
        all_cells = trail_set.union(claimed_territory)
        enclosed_cells = set()
        
        # For MVP, consider the trail itself as the claimed area
        # In production, implement proper flood-fill algorithm
        for cell in trail_set:
            neighbors = self.get_h3_neighbors(cell)
            enclosed_cells.update(neighbors.intersection(all_cells))
        
        return enclosed_cells if len(enclosed_cells) >= 3 else None