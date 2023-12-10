# 光源オブジェクトのファクトリー
class LightFactory
	# 太陽光の生成（ポイントライトで代用する）
	def self.create_sun_light
		sun = Mittsu::PointLight.new(0xffffff)
		sun.position.set(1, 20, 1)
		sun
	end
end