#coding: Windows-31J

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
  
  it "�T�C�Y�w��ŃJ�������`�ł��邱��" do
    mapper = define_layout do
      col :field1, 2
      col :field2, 1
    end
    rt = mapper.map(%w(12 3).join)
    rt.field1.should == "12"
    rt.field2.should == "3"
  end
  
  it "�T�C�Y�̔z��ŃJ�������`����Ƃ��̌��ŕ������ꂽ�z��ɂȂ邱��" do
    mapper = define_layout do
      col :f1, 2
      col :f2, [1, 2, 3]
      col :f3, [4] * 2
    end
    
    rt = mapper.map(%w(12 a bb ccc 1234 5678).join)
    rt.f1.should == "12"
    rt.f2.should == %w(a bb ccc)
    rt.f3.should == %w(1234 5678)
  end
  
  it "���C�A�E�g�ɖ��O�������邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
    end
    rt = mapper.map(%w(12 3).join, :layout1)
    rt.f1.should == "12"
    rt.f2.should == "3"
  end
  
  it "���C�A�E�g�����w�肵�Ă��Ȃ��ꍇ:default_layout�Œ�`����Ă��邱��" do
    mapper = define_layout do
      col :f1, 2
    end
    
    rt = mapper.map(%w(12).join, :default_layout)
    rt.f1.should == "12"
  end
  
  it "���郌�C�A�E�g�ŕʂ̃��C�A�E�g(�ȉ��T�u���C�A�E�g)���g���邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, :layout1
    end
    rt = mapper.map(%w(12 3).join)
    rt.f.f1.should == "12"
    rt.f.f2.should == "3"
  end
  
  it "�T�u���C�A�E�g�̔z�����`�ł��邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, [:layout1, :layout1]
    end
    rt = mapper.map(%w(12 3 ab c).join)
    rt.f[0].f1.should == "12"
    rt.f[0].f2.should == "3"
    rt.f[1].f1.should == "ab"
    rt.f[1].f2.should == "c"
  end
  
  it "�z��ɂ̓T�C�Y�ł��T�u���C�A�E�g�ł��w��ł��邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 2
        col :f2, 1
      end
      
      col :f, [:layout1, 1, 2]
    end
    rt = mapper.map(%w(12 3 a bc).join)
    rt.f[0].f1.should == "12"
    rt.f[0].f2.should == "3"
    rt.f[1].should == "a"
    rt.f[2].should == "bc"
  end
  
  it "�����̃��C�A�E�g���`�ł��邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f1, 1
      end
      
      layout :layout2 do
        col :f2, 2
      end
    end
    rt = mapper.map(%w(1).join, :layout1)
    rt.f1.should == "1"
    
    rt = mapper.map(%w(ab).join, :layout2)
    rt.f2.should == "ab"
  end
  
  it "�ϊ����ɃA�N�V�������`�����ꍇ���̖߂�l�Ń}�b�s���O����邱��" do
    mapper = define_layout do
      col :f1, 2 do |v|
        v + v
      end
    end
    
    rt = mapper.map(%w(12).join, :default_layout)
    rt.f1.should == "1212"
  end
  
  it "�����O�X�w��̃��C�A�E�g�̃����O�X���擾�ł��邱��" do
    mapper = define_layout do
      col :f1, 2 
    end
    
    mapper.get_layout.length.should == 2
  end
  
  it "�z��w��̃��C�A�E�g�̃����O�X���擾�ł��邱��" do
    mapper = define_layout do
      col :f1, [1, 2, 3]
    end
    
    mapper.get_layout.length.should == 6
  end
  
  it "�T�u���C�A�E�g�w��̃��C�A�E�g�̃����O�X���擾�ł��邱��" do
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
    
    mapper.get_layout.length.should == 4
  end
  
  it "�z��+�T�u���C�A�E�g�w��̃��C�A�E�g�̃����O�X���擾�ł��邱��" do
    mapper = define_layout do
      layout :layout1 do
        col :f, 1
      end
      col :f1, [10, :layout1, 1]
    end
    mapper.get_layout.length.should == 12
  end
  
  it "���C�A�E�g�Ƀ����O�X����(���Ȃ��Ƃ��f�[�^�̂ق�������)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�̕��������Ă��G���[�ɂȂ�Ȃ�����" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    rt = mapper.map("12345", :layout1)
    rt.f.should == "12"
  end

  it "���C�A�E�g�Ƀ����O�X����(���Ȃ��Ƃ��f�[�^�̂ق�������)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�̕����Z���ꍇ��O���������邱��" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    proc {
      mapper.map("1", :layout1)
    }.should raise_error
  end
  
  it "���C�A�E�g�Ƀ����O�X����(�f�[�^�����Ɠ���)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�̕��������ƃG���[�ɂȂ邱��" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
    end
    proc {
      mapper.map("12345", :layout1)
    }.should raise_error
  end
  
  it "���C�A�E�g�Ƀ����O�X����(�f�[�^�����Ɠ���)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�̕����Z���ƃG���[�ɂȂ邱��" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
    end
    proc {
      mapper.map("1", :layout1)
    }.should raise_error
  end
  
  it "���C�A�E�g�Ƀ����O�X����(�f�[�^�����Ɠ���)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�Ɠ����ꍇ�̓G���[���������Ȃ�����" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_STRICT do
        col :f, 2
      end
    end
    
    rt = mapper.map("12", :layout1)
    rt.f.should == "12"
  end
  
  it "���C�A�E�g�Ƀ����O�X����(�f�[�^�������͒���)���w�肳�ꂽ�ꍇ�f�[�^�̃����O�X�̕����Z���ƃG���[�ɂȂ邱��" do
    mapper = define_layout do
      layout :layout1, FixedLayoutMapper::LENGTH_CONDITION_ALLOW_LONG do
        col :f, 2
      end
    end
    proc {
      mapper.map("1", :layout1)
    }.should raise_error
  end
end
