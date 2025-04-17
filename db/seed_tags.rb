require './app'

tag_names = ["ロック", "ポップ", "アイドル", "EDM", "フェス飯", "雨対策"]
tag_names.each do |name|
  Tag.find_or_create_by(name: name)
end