#==============================================================================
#
# ¥ Yami Engine Ace - Basic Module
# -- Last Updated: 2012.04.27
# -- Level: Nothing
# -- Requires: n/a
#
#==============================================================================

$imported = {} if $imported.nil?
$imported["YSE-BasicModule"] = true

#==============================================================================
# ¥ Updates
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# 2012.04.27 - Added Notetags Initializer.
# 2012.03.24 - Added Parse Range Keys.
# 2012.03.17 - Updated Load Data Method.
# 2012.03.13 - Remove requirements mechanic.
# 2012.03.11 - Change in requirements mechanic.
# 2012.03.02 - Added Message Box.
# 2012.03.01 - Started and Finished Script.
#
#==============================================================================
# ¥ Introduction
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script provides many methods for Yami Engine Ace.
#
#==============================================================================
# ¥ Instructions
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# To install this script, open up your script editor and copy/paste this script
# to an open slot below ¥ Materials/‘fÞ but above ¥ Main. Remember to save.
#
#==============================================================================
# ¥ Compatibility
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# This script is made strictly for RPG Maker VX Ace. It is highly unlikely that
# it will run with RPG Maker VX without adjusting.
#
#==============================================================================

#==============================================================================
# ¥ Configuration
#==============================================================================

module YSE

  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # - External Data Configuration -
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  DATA_CONFIGURATION = { # Start here.
    :ext        =>  "rvdata2",   # Data File Extension.
    :salt       =>  "cl",        # Salt. Make an unique two-character phrase.
                                 # Must be 2 characters.
    :unique     =>  "z8x8273ac", # Unique phrase. Must be at least 1 character.
    :comp_level =>  9,           # Level from 1 to 9. Best Speed at 1, Best
                                 # Compress at 9.
  } # Do not delete this.

end

#==============================================================================
# ¥ Editting anything past this point may potentially result in causing
# computer damage, incontinence, explosion of user's head, coma, death, and/or
# halitosis so edit at your own risk.
#==============================================================================

#==============================================================================
# ¡ YSE - Basic Module
#==============================================================================

module YSE

  #--------------------------------------------------------------------------
  # message_box
  #--------------------------------------------------------------------------
  def self.message_box(title, message)
    api = Win32API.new('user32','MessageBox',['L', 'P', 'P', 'L'],'I')
    api.call(0,message,title,0)
  end

  #--------------------------------------------------------------------------
  # charset
  #--------------------------------------------------------------------------
  def self.charset
    result = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789"
    result
  end

  #--------------------------------------------------------------------------
  # make_random_string
  #--------------------------------------------------------------------------
  def self.make_random_string(length = 6)
    result = ""
    while result.size < length
      result << charset[rand(charset.size)]
    end
    result
  end

  #--------------------------------------------------------------------------
  # make_filename
  #--------------------------------------------------------------------------
  def self.make_filename(filename, dir = "")
    ext = DATA_CONFIGURATION[:ext]
    result = "#{dir}/#{filename}.#{ext}"
    result
  end

  #--------------------------------------------------------------------------
  # compress_data
  #--------------------------------------------------------------------------
  def self.compress_data(data, comp_level = nil)
    compress_level = comp_level.nil? ? DATA_CONFIGURATION[:comp_level] : comp_level
    result = Zlib::Deflate.deflate(Marshal.dump(data), compress_level)
    result
  end

  #--------------------------------------------------------------------------
  # decompress_data
  #--------------------------------------------------------------------------
  def self.decompress_data(data)
    result = Zlib::Inflate.inflate(Marshal.load(data))
    result
  end

  #--------------------------------------------------------------------------
  # make_hash
  #--------------------------------------------------------------------------
  def self.make_hash(string = "")
    salt = DATA_CONFIGURATION[:salt]
    result = string.crypt(salt)
    result = result + DATA_CONFIGURATION[:unique]
    result
  end

  #--------------------------------------------------------------------------
  # save_data
  #--------------------------------------------------------------------------
  def self.save_data(filename, data_hash)
    File.open(filename, "wb") do |file|
      Marshal.dump(compress_data(data_hash), file)
    end
    return true
  end

  #--------------------------------------------------------------------------
  # save_data
  #--------------------------------------------------------------------------
  def self.load_data(filename, method, index = 0, ext = nil)
    File.open(filename, "rb") do |file|
      index.times { Marshal.load(file) }
      if ext
        case ext
        when :mtime
          method.call(Marshal.load(decompress_data(file)), file.mtime)
        end
      else
        method.call(Marshal.load(decompress_data(file)))
      end
    end
    return true
  end

  #--------------------------------------------------------------------------
  # parse_range
  #--------------------------------------------------------------------------
  def self.parse_range(hash)
    result = {}
    hash.each { |key, value|
      if key.is_a?(Range)
        key.each { |id| result[id] = value }
      else
        result[key] = value
      end
    }
    result
  end

  #--------------------------------------------------------------------------
  # patch_start
  #--------------------------------------------------------------------------
  def self.patch_start
    return unless $imported["YSE-PatchSystem"]
    SceneManager.call(Scene_Patch_YSE)
  end

end # YSE - Basic Module

#==============================================================================
# ¡ DataManager
#==============================================================================

module DataManager

  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_yebm load_database; end
  def self.load_database
    load_database_yebm
    load_notetags_ye
  end

  #--------------------------------------------------------------------------
  # new method: load_notetags_ye
  #--------------------------------------------------------------------------
  def self.load_notetags_ye
    groups = [$data_actors, $data_classes, $data_skills, $data_items, $data_weapons,
              $data_armors, $data_enemies, $data_states]
    groups.each { |group|
      group.each { |obj|
        next if obj.nil?
        obj.notetags_initialize
      }
    }
  end

end # DataManager

#==============================================================================
# ¡ RPG::BaseItem
#==============================================================================

class RPG::BaseItem

  #--------------------------------------------------------------------------
  # new method: notetags_initialize
  #--------------------------------------------------------------------------
  def notetags_initialize
    @notelines = []
    #---
    self.note.split(/[\r\n]+/).each { |line|
      @notelines.push(line)
    } # self.note.split
    #---
    notetags_reader
  end

  #--------------------------------------------------------------------------
  # new method: notetags_reader
  #--------------------------------------------------------------------------
  def notetags_reader
    # Reading Notetags.
  end

end # RPG::BaseItem

#==============================================================================
# ¡ System Errors
#==============================================================================

if YSE::DATA_CONFIGURATION[:salt].size < 2
  YSE.message_box("YSE - Basic Module", "Salt must have at least 2 characters.")
  exit
end

if YSE::DATA_CONFIGURATION[:unique].size < 1
  YSE.message_box("YSE - Basic Module", "Unique phrase must have at least 1 character.")
  exit
end

#==============================================================================
#
# ¥ End of File
#
#==============================================================================
