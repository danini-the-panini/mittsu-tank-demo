# テクスチャ・ノーマルマップ用ファクトリー
# 同じテクスチャを毎回ロードし直さないよう、キャッシングを有効にしている点に注意
class TextureFactory
	# 1文字を表すテクスチャマップの生成
	def self.create_string(char)
		@@char_textures ||= {}
		@@char_textures[char] ||= Mittsu::ImageUtils.load_texture("images/string_#{char}.png")
		@@char_textures[char]
	end

	# 任意のテクスチャマップの生成
	def self.create_texture_map(filename)
		@@maps ||= {}
		@@maps[filename] ||= Mittsu::ImageUtils.load_texture("images/#{filename}")
		@@maps[filename]
	end

	# 任意のノーマルマップの生成
	def self.create_normal_map(filename)
		@@normals ||= {}
		@@normals[filename] ||= Mittsu::ImageUtils.load_texture("images/#{filename}")
		@@normals[filename]
	end

	# タイトル画面の説明用文字列テクスチャを生成
	def self.create_title_description
		Mittsu::ImageUtils.load_texture("images/title_description.png")
	end

	# エンディング画面の説明用文字列テクスチャを生成
	def self.create_ending_description
		Mittsu::ImageUtils.load_texture("images/ending_description.png")
	end
end