# 指定フレーム経過後に一瞬で表示されるパネルオブジェクト
class Panel
	attr_accessor :mesh

	def initialize(width: 0.1, height: 0.1, start_frame: 0, duration: 120, map: nil)
		# オブジェクト誕生時からの経過フレーム数をカウントする
		@count = 0

		# アニメーションを開始する経過フレーム数を保持
		@start_frame = start_frame

		# アニメーションを継続するフレーム数を保持
		@duration = duration

		# アニメーションを終了する経過フレーム数を計算
		@len = start_frame + duration

		# 平面ジオメトリによるパネルメッシュを生成
		self.mesh = MeshFactory.create_panel(width: width, height: height, map: map)

		# パネルメッシュを裏返しておく
		# ※ 平面ジオメトリ（PlaneGeometry）は、表面しか表示されない特性を利用している
		self.mesh.rotate_x(Math::PI)
	end

	# 1フレーム分の進行処理
	def play
		# カウンターがアニメーション対象範囲に入ったら、アニメーションを開始する
		if @start_frame < @count && @count < @len
			animate
		end
		@count += 1 if @count <= @len # フレームカウンタを進行させる
	end

	# アニメーション処理
	def animate
		# 一気に表面に切り替える
		self.mesh.rotation.x = 0
	end
end
