module Cache
  def self.grid(filename)
    load_bitmap("Graphics/Grid/", filename)
  end
end

module Revoked
  module Grid

    RadiusY = 1
    RadiusX = 4
    MaxHeight = 1 + 2 * RadiusY
    MaxWidth  = 1 + 2 * RadiusX

    TileHeight = 50
    TileWidth  = 58

    TileXOffset = -3
    TileYOffset = -10

    UnitXOffset = 32
    UnitYOffset = 48

    DefaultPositions = {
      1 => [0,1], # Clement
      2 => [1,2], # Amaina
      3 => [1,1], # Vermund
      4 => [-1,3] # Rinore
    }

    # Grid methods
    def self.position(x_index, y_index)
      result = {}

      w = TileWidth
      h = TileHeight
      base_x = Graphics.width / 2
      base_y = Graphics.height / 2
      x_offset = TileXOffset - (0.5 * w).to_i
      y_offset = TileYOffset - (0.5 * h).to_i
      result[:x] = base_x + x_offset + ((x_index + 0.5 * y_index) * w).to_i
      result[:y] = base_y + y_offset + y_index * h

      return result
    end

    def self.distance_between_tile(dest, orig)
      return distance_between_rc(dest.coordinate_rc, orig.coordinate_rc)
    end

    def self.distance_between_rc(dest, orig)
      return [dest[1] - orig[1], dest[0] - orig[0]].max
    end

    # Area building methods
    # get the indices of all nearby tiles with a given radius. [y, x]
    def self.calc_radius(tile_index = [0,0], radius = 1)
      offset_x = tile_index[1]
      offset_y = tile_index[0]
      radius_x = radius
      radius_y = radius

      result = []

      (-radius_y..radius_y).each do |row|
        left_ind  = row < 0 ? -radius_x - row : -radius_x
        right_ind = row > 0 ? radius_x - row : radius_x

        (left_ind..right_ind).each do |col|
          result.push([row + offset_y, col + offset_x])
        end
      end
      return result
    end


    #--------------------------------------------------------------------------
    # ■ Get array of spaces based on an item's grid tags and any battler mods.
    #==========================================================================
    def self.make_area(grid, origin, item)
      range = item.ability_range
      selection_tags = item.grid_selectable_tags
      area_tags = item.grid_area_tags

      # Array of tiles.
      selectable = []
      selectable.push(origin) if selection_tags.include?(:self)

      selection_tags.each do |tag|
        case tag
        when :radius
          selectable += grid.tiles_from_coordinates(calc_radius(origin, range))
        end
      end
      return selectable
    end

    def self.auto_cursor(grid, origin, selectable, item)
      anchor_coordinates = []
      target_type = item.grid_target_type

      can_target_self = item.grid_selectable_tags.include?(:not_self)

      if target_type == :self
        return origin
      end

      targets_in_range = unit_distances_in_area(grid, selectable, origin)
      return origin if targets_in_range.empty?

      msgbox_p(targets_in_range)
      if target_type == :enemy
        targets_in_range.reject {|tuple| !tuple[0].enemy?}
        anchor_coordinates = targets_in_range[1][1]
      elsif target_type == :ally && !can_target_self
        targets_in_range.reject {|tuple| !tuple[0].actor?}
        anchor_coordinates = targets_in_range[1][1]
      elsif target_type == :ally_dead
        targets_in_range.reject {|tuple| !tuple[0].actor? && !tuple[0].dead?}
        anchor_coordinates = targets_in_range[1][1]
      end
      return anchor_coodinates
    end

    # return an array of battlers in the given region.
    def self.units_in_area(grid, tiles)
      units = tiles.collect {|tile| tile.unit_contents }.compact.uniq
      return units
    end

    # return an array of enemy, distance, tile trios.
    def self.unit_distances_in_area(grid, tiles, origin)
      units = {}
      tiles.each do |tile|
        battlers = tile.unit_contents
        battlers.each do |b|
          dist = distance_between_tile(tile, origin)
          units[b] = units[b].nil ? [dist, tile] : [[dist, units[b]].min, tile]
        end
      end
      return units.sort_by {|_,dist| dist }
    end

    def self.wtf(grid)
      msgbox_p(grid.get(0,0))
    end

  end # Grid module
end
