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
