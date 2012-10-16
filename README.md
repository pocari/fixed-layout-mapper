Sample
====
    require 'pp'
    require 'fixed-layout-mapper'
    
    mapper = FixedLayoutMapper::Mapper.define_layout do
      layout :sub_layout do
        col :sub_f1, 1
        col :sub_f2, 2
      end
    
      col :f1, 5 
      col :f2, :sub_layout
      col :f3, [2] * 3
      col :f4, [1, 2, :sub_layout]
      col :f5, 3 do |v|
        v * 2
      end
    end
    
    data = %w(12345 a bb 00 11 22 a bb c dd 123)
    pp mapper.map(data.join)
    #=> #<struct 
    #    f1="12345",
    #    f2=#<struct  sub_f1="a", sub_f2="bb">,
    #    f3=["00", "11", "22"],
    #    f4=["a", "bb", #<struct  sub_f1="c", sub_f2="dd">],
    #    f5="123123">

Detail
====

Define columns
----
Layout definition is started in `define_layout' method.

    mapper = FixedLayoutMapper::Mapper.define_layout do
      definitions...
    end

Columns are defined by `col' method.

    col symbol, record_def

record_def is 
 * numeric: define column which cut the string with its width.

        #ex)
        mapper = FixedLayoutMapper::Mapper.define_layout do
          col :f, 3
        end
        
        p mapper.map("0123")
        #=> #<struct f="012">

 * array: define array column with use its each contents.

        #ex)
        mapper = FixedLayoutMapper::Mapper.define_layout do
          col :f1, [1, 2]
          col :f2, [1] * 3
        end
        
        p mapper.map("001123")
        #=> #<struct f1=["0", "01"], f2=["1", "2", "3"]>

 * sub_layout_key: define column which use its layout.  
   see Sub layout.

Sub layout
----

A col method call in top level is implicitly defined in default layout.  
if you want to name to layout, you can use `layout' method.
    
    layout layout_name(symbol) do
        column definitions...
    end

When sub layout is defined, you can use its layout in other layout definition.

    mapper = FixedLayoutMapper::Mapper.define_layout do
      layout :sub1 do
        col :sub_f1, 1
        col :sub_f2, 2
      end
      col :f1, 1
      col :f2, :sub1
    end

    p mapper.map("0123")
    #=> #<struct f1="0", f2=#<struct sub_f1="1", sub_f2="23">>

You can also use sub layout in array def.

    mapper = FixedLayoutMapper::Mapper.define_layout do
      layout :sub1 do
        col :sub_f1, 1
        col :sub_f2, 2
      end
      col :f1, [1, :sub1]
    end

    p mapper.map("0123")
    #=> #<struct f1=["0", #<struct sub_f1="1", sub_f2="23"]>

you can use sub layout in map method.  
if symbol is passed to the second argument in map method, use its layout.

    mapper = FixedLayoutMapper::Mapper.define_layout do
      layout :sub1 do
        col :sub_f1, 1
        col :sub_f2, 2
      end
      col :f1, [1, :sub1]
    end

    p mapper.map("0123")
    #=> #<struct f1=["0", #<struct sub_f1="1", sub_f2="23"]>
    p mapper.map("0123", :sub1)
    #=> #<struct sub_f1="0", sub_f2="12">


Convertion
----

If col method is given block, the pre-convert value is passed to the block and  
the field value becomes the return value of the block.

    mapper = FixedLayoutMapper::Mapper.define_layout do
      col :f1, 3 do |v|
        v + "_" + v
      end
      col :f2, 3, &:upcase
    end

    p mapper.map("012abc")
    #=> #<struct f1="012_012", f2="ABC">
