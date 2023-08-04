require "spec_helper"

describe ActsAsTaggableArrayOn::Taggable do
  before do
    @user1 = User.create name: "Tom", colors: ["red", "blue"], sizes: ["medium", "large"], codes: [456, 789], roles: ["user"], references: ["308f35c6-f819-4faa-9bba-2457de1dde25"]
    @user2 = User.create name: "Ken", colors: ["black", "white", "red"], sizes: ["small", "large"], codes: [123, 789], roles: ["User"], references: ["e32434a0-39c2-44cc-9c1e-f4c7eebaafb3"]
    @user3 = User.create name: "Joe", colors: ["black", "blue"], sizes: ["small", "medium", "large"], codes: [123, 456, 789], roles: ["login"], references: ["41d9033b-80e1-4784-90f6-0c9eb7537cac"]
    @admin1 = Admin.create name: "Dick", colors: ["purple", "orange"], sizes: ["medium", "large"], codes: [123, 456, 789], roles: ["USER", "Admin"], references: ["308f35c6-f819-4faa-9bba-2457de1dde25", "e32434a0-39c2-44cc-9c1e-f4c7eebaafb3"]
    @admin2 = Admin.create name: "Harry", colors: ["white", "blue"], sizes: ["small", "large"], codes: [456, 123], roles: ["Admin"], references: ["41d9033b-80e1-4784-90f6-0c9eb7537cac"]

    User.acts_as_taggable_array_on :colors
    User.acts_as_taggable_array_on :sizes
    User.acts_as_taggable_array_on :roles
    User.acts_as_taggable_array_on :references
    User.taggable_array :codes

  end

  context "without database table" do
    it "doesn't fail on class method call" do
      class Dummy < ActiveRecord::Base; end
      Dummy.acts_as_taggable_array_on :tags
    end
  end

  describe "#acts_as_taggable_array_on" do
    it "defines named scope to match any tags" do
      expect(User).to respond_to(:with_any_colors)
    end
    it "defines named scope to match all tags" do
      expect(User).to respond_to(:with_all_colors)
    end
    it "defines named scope not to match any tags" do
      expect(User).to respond_to(:without_any_colors)
    end
    it "defines named scope not to match all tags" do
      expect(User).to respond_to(:without_all_colors)
    end
  end

  describe "#taggable_array_on" do
    it "defines named scope to match any tags" do
      expect(User).to respond_to(:with_any_codes)
    end
    it "defines named scope to match all tags" do
      expect(User).to respond_to(:with_all_codes)
    end
    it "defines named scope not to match any tags" do
      expect(User).to respond_to(:without_any_codes)
    end
    it "defines named scope not to match all tags" do
      expect(User).to respond_to(:without_all_codes)
    end
  end

  it "should define table name un-ambiguously" do
    sql = User.with_any_sizes(["small"]).to_sql
    expect(sql).to eql("SELECT \"users\".* FROM \"users\" WHERE (users.sizes && ARRAY['small']::text[])")

    sql = User.with_all_sizes(["small"]).to_sql
    expect(sql).to eql("SELECT \"users\".* FROM \"users\" WHERE (users.sizes @> ARRAY['small']::text[])")

    sql = User.without_any_sizes(["small"]).to_sql
    expect(sql).to eql("SELECT \"users\".* FROM \"users\" WHERE NOT (users.sizes && ARRAY['small']::text[])")

    sql = User.without_all_sizes(["small"]).to_sql
    expect(sql).to eql("SELECT \"users\".* FROM \"users\" WHERE NOT (users.sizes @> ARRAY['small']::text[])")
  end

  it "should work with ::text typed array" do
    expect(User.with_any_sizes(["small"])).to match_array([@user2, @user3, @admin2])
    expect(User.with_all_sizes(["small", "large"])).to match_array([@user2, @user3, @admin2])
    expect(User.without_any_sizes("medium")).to match_array([@user2, @admin2])
    expect(User.without_all_sizes("medium")).to match_array([@user2, @admin2])
  end

  it "should work with ::citext typed array" do
    expect(User.with_any_roles(["admin"])).to match_array([@admin1, @admin2])
    expect(User.with_all_roles(["User", "Admin"])).to match_array([@admin1])
    expect(User.without_any_roles("USER")).to match_array([@user3, @admin2])
    expect(User.without_all_roles("UseR")).to match_array([@user3, @admin2])
  end

  it "should work with ::uuid typed array" do
    expect(User.with_any_references(["308f35c6-f819-4faa-9bba-2457de1dde25"])).to match_array([@user1, @admin1])
    expect(User.with_all_references(["308f35c6-f819-4faa-9bba-2457de1dde25", "e32434a0-39c2-44cc-9c1e-f4c7eebaafb3"])).to match_array([@admin1])
    expect(User.without_any_references("308f35c6-f819-4faa-9bba-2457de1dde25")).to match_array([@user2, @user3, @admin2])
    expect(User.without_all_references(["308f35c6-f819-4faa-9bba-2457de1dde25", "e32434a0-39c2-44cc-9c1e-f4c7eebaafb3"])).to match_array([@user1, @user2, @user3, @admin2])
  end

  it "should work with ::integer typed array" do
    expect(User.with_any_codes([123])).to match_array([@user2, @user3, @admin1, @admin2])
    expect(User.with_all_codes([123, 789])).to match_array([@user2, @user3, @admin1])
    expect(User.without_any_codes(456)).to match_array([@user2])
    expect(User.without_all_codes(456)).to match_array([@user2])
  end

  describe "#with_any_tags" do
    it "returns users having any tags of args" do
      expect(User.with_any_colors(["red", "blue"])).to match_array([@user1, @user2, @user3, @admin2])
      expect(User.with_any_colors("red, blue")).to match_array([@user1, @user2, @user3, @admin2])
    end
  end

  describe "#with_all_tags" do
    it "returns users having all tags of args" do
      expect(User.with_all_colors(["red", "blue"])).to match_array([@user1])
      expect(User.with_all_colors("red, blue")).to match_array([@user1])
    end
  end

  describe "#without_any_tags" do
    it "returns users not having any tags of args" do
      expect(User.without_any_colors(["red", "blue"])).to match_array([@admin1])
      expect(User.without_any_colors("red, blue")).to match_array([@admin1])
    end
  end

  describe "#without_all_tags" do
    it "returns users not having all tags of args" do
      expect(User.without_all_colors(["red", "blue"])).to match_array([@user2, @user3, @admin1, @admin2])
      expect(User.without_all_colors("red, blue")).to match_array([@user2, @user3, @admin1, @admin2])
    end
  end

  describe "#all_colors" do
    it "returns all of tag_name" do
      expect(User.all_colors).to match_array([@user1, @user2, @user3, @admin1, @admin2].map(&:colors).flatten.uniq)
      expect(Admin.all_colors).to match_array([@admin1, @admin2].map(&:colors).flatten.uniq)
    end

    it "returns filtered tags for tag_name with block" do
      expect(User.all_colors { where(name: ["Ken", "Joe"]) }).to match_array([@user2, @user3].map(&:colors).flatten.uniq)
      expect(Admin.all_colors { where(name: ["Dick", "Harry"]) }).to match_array([@admin1, @admin2].map(&:colors).flatten.uniq)
    end

    it "returns filtered tags for tag_name with prepended scope" do
      expect(User.where("tag like ?", "bl%").all_colors).to match_array([@user1, @user2, @user3].map(&:colors).flatten.uniq.select { |name| name.start_with? "bl" })
      expect(Admin.where("tag like ?", "bl%").all_colors).to match_array([@admin2].map(&:colors).flatten.uniq.select { |name| name.start_with? "bl" })
    end

    it "returns filtered tags for tag_name with prepended scope and bock" do
      expect(User.where("tag like ?", "bl%").all_colors { where(name: ["Ken", "Joe"]) }).to match_array([@user2, @user3].map(&:colors).flatten.uniq.select { |name| name.start_with? "bl" })
    end
  end

  describe "#colors_cloud" do
    it "returns tag cloud for tag_name" do
      expect(User.colors_cloud).to match_array(
        [@user1, @user2, @user3, @admin1, @admin2].map(&:colors).flatten.group_by(&:to_s).map { |k, v| [k, v.count] }
      )
    end

    it "returns filtered tag cloud for tag_name with block" do
      expect(User.colors_cloud { where(name: ["Ken", "Joe"]) }).to match_array(
        [@user2, @user3].map(&:colors).flatten.group_by(&:to_s).map { |k, v| [k, v.count] }
      )
    end

    it "returns filtered tag cloud for tag_name with prepended scope" do
      expect(User.where("tag like ?", "bl%").colors_cloud).to match_array(
        [@user1, @user2, @user3, @admin2].map(&:colors).flatten.group_by(&:to_s).map { |k, v| [k, v.count] }.select { |name, count| name.start_with? "bl" }
      )
    end

    it "returns filtered tag cloud for tag_name with prepended scope and block" do
      expect(User.where("tag like ?", "bl%").colors_cloud { where(name: ["Ken", "Joe"]) }).to match_array(
        [@user2, @user3].map(&:colors).flatten.group_by(&:to_s).map { |k, v| [k, v.count] }.select { |name, count| name.start_with? "bl" }
      )
    end
  end

  describe "with complex scope" do
    it "works properly" do
      expect(User.without_any_colors("white").with_any_colors("blue").order(:created_at).limit(10)).to eq [@user1, @user3]
    end
  end
end
