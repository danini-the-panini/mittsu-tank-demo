require_relative 'panel'

# 回転アニメーションをするパネルオブジェクト
class AnimatedPanel < Panel
	FPS = 60 # １秒間にレンダリングされるフレーム数

	# １フレーム分のアニメーション進行
	# アニメーション再生フレーム数（@duration）分の進行で丁度パネルが裏返るように１フレームの回転角を調整する
	def animate
		@theta ||= Math::PI / @duration
		self.mesh.rotate_x(@theta * (@duration / FPS / 2))
	end
end