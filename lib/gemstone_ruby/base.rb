
require 'ffi'    # Foreign Function Interface

module GemStone
  extend FFI::Library
  gciVersion = "3.1.0.4"
  ffi_lib [
    "gcirpc-#{ gciVersion }-64",       # this must be in LD_LIBRARY_PATH
    File.expand_path("../../../bin/libgcirpc-#{ gciVersion }-64.so", __FILE__),
    File.expand_path("../../../bin/libgcirpc-#{ gciVersion }-64.dylib", __FILE__)
  ]
  
  OOP_NIL = 20
  OOP_CLASS_STRING = 74753
  
  typedef :uint64, :OopType
  typedef :int32, :GciSessionIdType
  
  attach_function :GciErr,          [:pointer                             ], :bool
  attach_function :GciExecuteStr,   [:string, :OopType                    ], :OopType, :blocking => true
  attach_function :GciFetchChars_,  [:OopType, :uint64, :pointer, :uint64 ], :uint64
  attach_function :GciFetchClass,   [:OopType                             ], :OopType
  attach_function :GciFetchObjImpl, [:OopType                             ], :uint8
  attach_function :GciFetchSize_,   [:OopType                             ], :uint64
  attach_function :GciGetSessionId, [                                     ], :GciSessionIdType
  attach_function :GciHardBreak,    [                                     ], :void
  attach_function :GciInit,         [                                     ], :bool
  attach_function :GciLogin,        [:string, :string                     ], :bool, :blocking => true
  attach_function :GciLogout,       [                                     ], :void
  attach_function :GciOopToBool,    [:OopType                             ], :bool
  attach_function :GciOopToChar32,  [:OopType                             ], :uint32
  attach_function :GciOopToFlt,     [:OopType                             ], :double
  attach_function :GciOopToI64,     [:OopType                             ], :int64
  attach_function :GciSetNet,       [:string, :string, :string, :string   ], :void
  attach_function :GciSetSessionId, [:GciSessionIdType                    ], :void
  attach_function :GciShutdown,     [                                     ], :void
  attach_function :GciSoftBreak,    [                                     ], :void
  attach_function :GciVersion,      [                                     ], :string
  
  def GemStone.login(options={})
    options[:stone]    ||= "gs64stone"
    options[:gemnet]   ||= "!tcp@localhost#netldi:gs64ldi#task!gemnetobject"
    options[:user]     ||= "DataCurator"
    options[:password] ||= "swordfish"
    GemStone.GciSetNet(options[:stone], nil, nil, options[:gemnet])
    if (!GemStone.GciLogin(options[:user], options[:password]))
      raise GemStone.gciError()[:message]
    end
    return GciGetSessionId()  
  end
  

  def GemStone.executeString(string)
    oopValue = GemStone.GciExecuteStr(string, OOP_NIL)
    oop = OopType.new(oopValue)
    if oop.isNil;          return nil;      end
    if oop.isTrue;         return true;     end
    if oop.isFalse;        return false;    end
    if oop.isCharacter;    return oop.to_s; end
    if oop.isSmallDouble;  return oop.to_f; end
    if oop.isSmallInteger; return oop.to_i; end
    if oop.isString;    return oop.to_s;    end
    return oop
  end
  
  def GemStone.gciError()
    gciError = GemStone::GciErrSType.new
    haveErrorFlag = GemStone.GciErr(gciError)
    return haveErrorFlag ? gciError : nil
  end

  
  class GciErrSType < FFI::Struct
    layout :category,     :OopType,  
           :context,      :OopType,
           :exceptionObj, :OopType,
           :args,        [:OopType, 10],
           :number,       :uint32,
           :argCount,     :uint32,
           :fatal,        :uint8,
           :message,     [:char, 1025],
           :reason,      [:char, 1025]
  end
  
  class OopType
    def initialize(value)
      @value = value
    end
    
    def isBoolean;      return isFalse | isTrue;                                    end
    def isBytes;        return GemStone.GciFetchObjImpl(@value) === 1;              end
    def isCharacter;    return @value & 255 === 28;                                 end  
    def isFalse;        return @value === 12;                                       end
    def isIllegal;      return @value === 2;                                        end
    def isImmediate;    return 0 < @value & 6;                                      end  
    def isNil;          return @value === 20;                                       end
    def isSmallDouble;  return @value & 7 === 6;                                    end
    def isSmallInteger; return @value & 7 === 2;                                    end
    def isString;       return GemStone.GciFetchClass(@value) === OOP_CLASS_STRING; end
    def isTrue;         return @value === 268;                                      end
    
    def to_f
      if !isSmallDouble;  return nil;  end
      return GemStone.GciOopToFlt(@value)
    end
    
    def to_i
      if !isSmallInteger;  return nil;  end
      return GemStone.GciOopToI64(@value)
    end
    
    def to_s
      if isNil;         return "nil";     end
      if isTrue;        return "true";    end
      if isFalse;       return "false";   end
      if isSmallDouble; return to_f.to_s; end
      if isCharacter
        return GemStone.GciOopToChar32(@value).chr
      end
      if isString
        expectedSize = GemStone.GciFetchSize_(@value)
        memory = FFI::MemoryPointer.new(expectedSize + 1)
        actualSize = GemStone.GciFetchChars_(@value, 1, memory, expectedSize + 1)
        if (expectedSize != actualSize)
          raise "expected = #{ expectedSize }; actual = #{ actualSize }"
        end
        return memory.get_string(0)
      end
      return "OOP(#{ @value.to_s })"
    end
  end
end

GemStone.GciInit
