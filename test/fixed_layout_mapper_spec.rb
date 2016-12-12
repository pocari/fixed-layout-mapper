
$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')
require File.expand_path(File.dirname(__FILE__) + '/../lib/fixed-layout-mapper')
require 'rspec'

describe FixedLayoutMapper::Mapper do
  def define_layout(&block)
    FixedLayoutMapper::Mapper.define_layout(&block)
  end
  
  def genstr(ary)
    ary.join
  end
  
  it "サイズ指定でカラムを定義できること" do
    mapper = define_layout do
      col :field1, 2
      col :field2, 1
    end
    rt = mapper.map(%w(12 3).join)
    expect(rt.field1).to eq "12"
    expect(rt.field2).to eq "3"
  end
  
  it "サイズの配列でカラムを定義するとその桁で分割された配列になること" do
    mapper = define_layout do
      col :f1, 2
      col :f2, [1, 2, 3]
      col :f3, [4] * 2
    end
    
    rt = mapper.map(%w(12 a bb ccc 1234 5678).join)
    expect(rt.f1).to eq "12"
    expect(rt.f2).to eq %w(a bb ccc)
    expect(rt.f3).to eq %w(1234 5678)
  end
  
  it "レイアウトに名前をつけられること" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
    end
    rt = mapper.map(%w(12 3).join, :layout1)
    expect(rt.f1).to eq "12"
    expect(rt.f2).to eq "3"
  end
  
  it "レイアウト名を指定していない場合:default_layoutで定義されていること" do
    mapper = define_layout do
      col :f1, 2
    end
    
    rt = mapper.map(%w(12).join, :default_layout)
    expect(rt.f1).to eq "12"
  end
  
  it "あるレイアウトで別のレイアウト(以下サブレイアウト)を使えること" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, :layout1
    end
    rt = mapper.map(%w(12 3).join)
    expect(rt.f.f1).to eq "12"
    expect(rt.f.f2).to eq "3"
  end
  
  it "サブレイアウトの配列も定義できること" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, [:layout1, :layout1]
    end
    rt = mapper.map(%w(12 3 ab c).join)
    expect(rt.f[0].f1).to eq "12"
    expect(rt.f[0].f2).to eq "3"
    expect(rt.f[1].f1).to eq "ab"
    expect(rt.f[1].f2).to eq "c"
  end
  
  it "配列にはサイズでもサブレイアウトでも指定できること" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, [:layout1, 1, 2]
    end
    rt = mapper.map(%w(12 3 a bc).join)
    expect(rt.f[0].f1).to eq "12"
    expect(rt.f[0].f2).to eq "3"
    expect(rt.f[1]).to eq "a"
    expect(rt.f[2]).to eq "bc"
  end
  
  it "複数のレイアウトを定義できること" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 1
      end
      
      layout :layout2 do
        col :f2, 2
      end
    end
    rt = mapper.map(%w(1).join, :layout1)
    expect(rt.f1).to eq "1"
    
    rt = mapper.map(%w(ab).join, :layout2)
    expect(rt.f2).to eq "ab"
  end
  
  it "変換時にアクションを定義した場合その戻り値でマッピングされること" do
    mapper = define_layout do
      col :f1, 2 do |v|
        v + v
      end
    end
    
    rt = mapper.map(%w(12).join, :default_layout)
    expect(rt.f1).to eq "1212"
  end
  
  it "レングス指定のレイアウトのレングスが取得できること" do
    mapper = define_layout do
      col :f1, 2 
    end
    
    expect(mapper.get_layout.length).to eq 2
  end
  
  it "配列指定のレイアウトのレングスが取得できること" do
    mapper = define_layout do
      col :f1, [1, 2, 3]
    end
    
    expect(mapper.get_layout.length).to eq 6
  end
  
  it "サブレイアウト指定のレイアウトのレングスが取得できること" do
    mapper = define_layout do
      layout :layout1 do
        col :f, 1
      end
      
      layout :layout2 do
        col :f ,3
      end
      
      col :f1, :layout1
      col :f2, :layout2
    end
    
    expect(mapper.get_layout.length).to eq 4
  end
  
  it "配列+サブレイアウト指定のレイアウトのレングスが取得できること" do
    mapper = define_layout do
      layout :layout1 do
        col :f, 1
      end
      col :f1, [10, :layout1, 1]
    end
    expect(mapper.get_layout.length).to eq 12
  end
  
  it "レイアウトにレングス制約(少なくともデータのほうが長い)を指定された場合データのレングスの方が長くてもエラーにならないこと" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    rt = mapper.map("12345", :layout1)
    expect(rt.f).to eq "12"
  end

  it "レイアウトにレングス制約(少なくともデータのほうが長い)を指定された場合データのレングスの方が短い場合例外が発生すること" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    expect {
      mapper.map("1", :layout1)
    }.to raise_error("byte length is too short")
  end
  
  it "レイアウトにレングス制約(データ長さと同じ)を指定された場合データのレングスの方が長いとエラーになること" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
    end

    expect {
      mapper.map("12345", :layout1)
    }.to raise_error("byte length is invalid")
  end
  
  it "レイアウトにレングス制約(データ長さと同じ)を指定された場合データのレングスの方が短いとエラーになること" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
    end
    expect {
      mapper.map("1", :layout1)
    }.to raise_error("byte length is invalid")
  end
  
  it "レイアウトにレングス制約(データ長さと同じ)を指定された場合データのレングスと同じ場合はエラーが発生しないこと" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
  end
    
    rt = mapper.map("12", :layout1)
    expect(rt.f).to eq "12"
  end
  
  it "レイアウトにレングス制約(データ長さよりは長い)を指定された場合データのレングスの方が短いとエラーになること" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    expect {
      mapper.map("1", :layout1)
    }.to raise_error("byte length is too short")
  end
end
