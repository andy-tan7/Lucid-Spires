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

    DefaultPositions = [[2,0]]

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

    # Area building methods
    
  end # Grid module

end
