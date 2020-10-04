module Mouse
  
  ClipCursor = Win32API.new('user32', 'ClipCursor', 'p', 'l')
  GetClientRect = Win32API.new('user32', 'GetClientRect', 'lp', 'i') if !const_defined?(:GetClientRect)
  GetWindowRect = Win32API.new('user32', 'GetWindowRect', 'lp', 'i') if !const_defined?(:GetWindowRect)
  
  class << self
    
    alias jet4747_update update
    def update(*args, &block)
      jet4747_update(*args, &block)
      ClipCursor.call(client_rect.pack('l4'))
    end
  end
  
  module_function
  
  def client_rect
    rect = [0, 0, 0, 0].pack('l4')
    GetWindowRect.call(@handle || @hwnd, rect)
    posi = rect.unpack('l4')[0..1]
    GetClientRect.call(@handle || @hwnd, rect)
    size = rect.unpack('l4')[2..3]
    scr = screen_to_client(*posi)
    x1 = posi[0] + scr[0].abs
    y1 = posi[1] + scr[1].abs
    x2 = size[0] + posi[0]
    y2 = size[1] + posi[1] + scr[1].abs
    rect = [x1, y1, x2, y2]
    rect
  end
end