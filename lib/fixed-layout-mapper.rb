require "fixed-layout-mapper/version"

module FixedLayoutMapper
  LENGTH_CONDITION_STRICT = :strict
  LENGTH_CONDITION_ALLOW_LONG = :allow_long
  
  class Mapper
    class ColumnMapper
      attr_accessor :layout_mapper, :converter
      def initialize(layout_mapper, converter = nil)
        @layout_mapper = layout_mapper
        @converter = converter
      end

      def convert(value)
        if @converter
          @converter.(value)
        else
          value
        end
      end
    end

    class SimpleMapper < ColumnMapper
      def initialize(layout_mapper, len, converter = nil)
        super layout_mapper, converter
        @len = len
      end
      
      def length
        @len
      end
      
      def map(bytes)
        value = bytes.take(@len).pack("C*").force_encoding(layout_mapper.encoding)
        #value = converter.(value) if converter
        [convert(value), bytes.drop(@len)]
      end
    end

    class SubLayoutMapper < ColumnMapper
      def initialize(layout_mapper, layout_id, converter = nil)
        super layout_mapper, converter
        @layout_id = layout_id
      end

      def map(bytes)
        value, rest = layout_mapper.get_layout(@layout_id).map(bytes, layout_mapper.get_result_class(@layout_id))
        [convert(value), rest]
      end
      
      def length
        layout_mapper.get_layout(@layout_id).length
      end
    end

    class ArrayMapper < ColumnMapper
      def initialize(layout_mapper, mappers, converter = nil)
        super layout_mapper, converter
        @mappers = mappers
      end

      def map(bytes)
        ret = []
        rest = @mappers.inject(bytes) do |acc, mapper|
          value, acc = mapper.map(acc)
          ret << value
          acc
        end
        [convert(ret), rest]
      end
      
      def length
        @mappers.inject(0) do |acc, m|
          acc += m.length
        end
      end
    end

    class Layout
      def initialize(length_condition)
        @length_condition = length_condition
        @layout = []
        @length = nil
      end

      def syms
        @layout.map{|e| e[0]}
      end

      def add(sym, mapper)
        @layout << [sym, mapper]
      end
      
      def length
        @length ||= calc_length
      end
      
      def calc_length
        @layout.inject(0) do |acc, (sym, mapper)|
          acc += mapper.length
        end
      end
      
      def map(bytes, result_class)
        case @length_condition
        when LENGTH_CONDITION_STRICT
          raise "byte length is invalid" unless bytes.length == length
        when LENGTH_CONDITION_ALLOW_LONG
          raise "byte length is too short" if bytes.length < length
        else
          raise "unknown LENGTH_CONDIGION #{@length_condition}"
        end
        
        obj = result_class.new
        rest = @layout.inject(bytes) do |acc, (sym, mapper)|
          value, acc = mapper.map(acc)
          obj[sym] = value
          acc
        end
        [obj, rest]
      end
    end

    class << self
      def define_layout(opts = {:encoding => Encoding.default_external}, &block)
        obj = Mapper.new(opts)
        obj.define_layout(&block)
        obj
      end
    end

    attr_reader :encoding, :length_condition
    def initialize(opts = {:encoding => Encoding.default_external})
      @current_layout = :default_layout
      @current_length_condition = LENGTH_CONDITION_ALLOW_LONG
      @layouts = {}
      @result_class = {}
      @length_conditions = {}
      @encoding = opts[:encoding]
    end

    def define_layout(&block)
      instance_eval(&block)
      build_layout
    end

    def map(data, layout_id = @current_layout)
      obj, = @layouts[layout_id].map(data.unpack("C*"), @result_class[layout_id])
      obj
    end

    def get_layout(layout_id = @current_layout)
      @layouts[layout_id]
    end

    def get_result_class(layout_id)
      @result_class[layout_id]
    end
    
    def length_condigion(value)
      @length_condition = value
    end
    
    private
    def build_layout
      @layouts.each do |layout_id, layout|
        @result_class[layout_id] = Struct.new(*layout.syms) do
          def to_hash
            each_pair.inject({}) do |acc, (key, value)|
              case
              when value.respond_to?(:to_hash)
                acc[key] = value.to_hash
              when Array === value
                acc[key] = value.map{|e|
                  if e.respond_to?(:to_hash)
                    e.to_hash
                  else
                    e
                  end
                }
              else
                acc[key] = value
              end
              acc
            end
          end
        end
      end
    end

    def layout(layout_id, length_condition = LENGTH_CONDITION_ALLOW_LONG, &block)
      change_current_layout(layout_id, length_condition) do
        instance_eval(&block)
      end
    end

    def col(sym, map_info, layout_id = @current_layout, &block)
      case map_info
      when Numeric
        col_len(sym, map_info, layout_id, block)
      when Symbol
        col_from_sub_layout(sym, map_info, layout_id, block)
      when Array
        col_array(sym, map_info, layout_id, block)
      end
    end
    
    def create_layout
      Layout.new(@current_length_condition)
    end
    
    def col_len(sym, len, layout_id = @current_layout, block)
      @layouts[layout_id] ||= create_layout
      @layouts[layout_id].add(sym, SimpleMapper.new(self, len, block))
    end

    def col_from_sub_layout(sym, sub_layout, layout_id = @current_layout, block)
      @layouts[layout_id] ||= create_layout
      @layouts[layout_id].add(sym, SubLayoutMapper.new(self, sub_layout, block))
    end

    def col_array(sym, array_param, layout_id = @current_layout, block)
      @layouts[layout_id] ||= create_layout
      @layouts[layout_id].add(sym, ArrayMapper.new(self,
        array_param.map{|arg|
          case arg
          when Numeric
            mapper_class = SimpleMapper
          when Symbol
            mapper_class = SubLayoutMapper
          else
            raise "elements must be Numeric or Symbol"
          end
          mapper_class.new(self, arg)
        }, block)
      )
    end

    def change_current_layout(layout, length_condition)
      tmp = @current_layout
      tmp = @current_length_condition
      @current_layout = layout
      @current_length_condition = length_condition
      yield
      @current_layout = tmp
      @current_length_condition = tmp
    end
  end
end
