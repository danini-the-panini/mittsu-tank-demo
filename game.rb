require 'mittsu'

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
ASPECT = SCREEN_WIDTH.to_f / SCREEN_HEIGHT.to_f

scene = Mittsu::Scene.new
skybox_scene = Mittsu::Scene.new
camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 0.1, 1000.0)
skybox_camera = Mittsu::PerspectiveCamera.new(75.0, ASPECT, 1.0, 100.0)

renderer = Mittsu::OpenGLRenderer.new width: SCREEN_WIDTH, height: SCREEN_HEIGHT, title: 'Hello World'
renderer.auto_clear = false
renderer.shadow_map_enabled = true
renderer.shadow_map_type = Mittsu::PCFSoftShadowMap

cube_map_texture = Mittsu::ImageUtils.load_texture_cube(
  [ 'rt', 'lf', 'up', 'dn', 'bk', 'ft' ].map { |path|
    File.join File.dirname(__FILE__), "back_#{path}.png"
  }
)

shader = Mittsu::ShaderLib[:cube]
shader.uniforms['tCube'].value = cube_map_texture



skybox_material = Mittsu::ShaderMaterial.new({
  fragment_shader: shader.fragment_shader,
  vertex_shader: shader.vertex_shader,
  uniforms: shader.uniforms,
  depth_write: false,
  side: Mittsu::BackSide
})

skybox = Mittsu::Mesh.new(Mittsu::BoxGeometry.new(100, 100, 100), skybox_material)
skybox_scene.add(skybox)

def set_repeat(tex)
  tex.wrap_s = Mittsu::RepeatWrapping
  tex.wrap_t = Mittsu::RepeatWrapping
  tex.repeat.set(1000, 1000)
end

floor = Mittsu::Mesh.new(
  Mittsu::BoxGeometry.new(1.0, 1.0, 1.0),
  Mittsu::MeshPhongMaterial.new(
    map: Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './back2_dn.png').tap { |t| set_repeat(t) },
    normal_map: Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './back2_dn.png').tap { |t| set_repeat(t) }
  )
)

guround_y=-20.0
floor.scale.set(10000.0, 10.0, 10000.0)
floor.position.y = guround_y
scene.add(floor)

ball_geometry = Mittsu::SphereGeometry.new(1.0, 16, 16)
ball_material = Mittsu::MeshPhongMaterial.new(env_map: cube_map_texture)
shiny_balls = 10.times.map do
  ball = Mittsu::Mesh.new(ball_geometry, ball_material)
  ball.position.set(rand * 35.0 - 10.0, rand * 25 + 5, rand * 35.0 - 40.0)
  scale = 0.5
  ball.scale.set(scale, scale, scale)
  scene.add(ball)
  ball
end


title_geometry = Mittsu::BoxGeometry.new(1.7, 1.5, 0.1)
title_texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), '3samurai.png')
title_material = Mittsu::MeshBasicMaterial.new(map: title_texture)
title_panel = Mittsu::Mesh.new(title_geometry, title_material)
title_panel.rotation.y = Math::PI
title_panel.rotation.x = Math::PI/6.0

ending_geometry = Mittsu::BoxGeometry.new(1.7, 1.5, 0.1)
ending_texture = Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), '3samurai_end.png')
ending_material = Mittsu::MeshBasicMaterial.new(map: ending_texture)
ending_panel = Mittsu::Mesh.new(ending_geometry, ending_material)
ending_panel.rotation.y = Math::PI
ending_panel.rotation.x = Math::PI/6.0

object = loader.load('tank.obj', 'tank.mtl')

tank = Mittsu::Object3D.new
body, wheels, turret, tracks, barrel = object.children.map { |o| o.children.first }
object.children.each do |o|
  o.children.first.material.metal = true
  tank.add(camera) if [body, wheels, tracks].include?(o.children.first)
end

title_panel.position.set(0.0, 1.53, -2.3)
tank.add(title_panel)

ending_panel.position.set(0.0, 1.53, -20)
tank.add(ending_panel)

turret.position.set(0.0, 0.17, -0.17)
tank.add(turret)


loader = Mittsu::OBJMTLLoader.new
tank = loader.load('drone.obj','drone.mtl')
tank.scale.set(0.1,0.1,0.1)
tank.print_tree


tank.add(camera)
tank.rotation.y = Math::PI
scene.add(tank)

scene.traverse do |child|
  child.receive_shadow = true
  child.cast_shadow = true
end

sunlight = Mittsu::HemisphereLight.new(0xd3c0e8, 0xd7ad7e, 0.7)
scene.add(sunlight)

light = Mittsu::SpotLight.new(0xffffff, 1.0)
light.position.set(0.0, 30.0, -30.0)

light.cast_shadow = true
light.shadow_darkness = 0.5

light.shadow_map_width = 2048
light.shadow_map_height = 2048

light.shadow_camera_near = 1.0
light.shadow_camera_far = 100.0
light.shadow_camera_fov = 60.0

light.shadow_camera_visible = false
scene.add(light)

camera.position.z = - 4.0
camera.position.y = + 3.0
camera.rotation.y = Math::PI
camera.rotation.x = Math::PI/6.0

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = skybox_camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
  skybox_camera.update_projection_matrix
end

JOYSTICK_DEADZONE = 0.1
JOYSTICK_SENSITIVITY = 0.05

def drive_ad(tank, amount)
  tank.translate_x(amount)
end

#前後移動
def drive_ws(tank, amount)
  tank.translate_z(amount)
end

#上下移動
def drive_ud(tank, amount)
  tank.translate_y(amount)
end

#左右カメラ移動
def rotate_tank(tank, amount)
  tank.rotation.y += amount
end

#上下カメラ移動
def lift_tank(tank, amount)
  tank.rotation.x += amount
end


x = 0
y = 0
renderer.window.run do
  shiny_balls.each do |ball|
    distance = ball.position.distance_to(tank.position)
    if distance < 1.0
      # 配列から削除
      shiny_balls.delete(ball)
      # シーンから削除
      scene.remove(ball)
      y = y + 1
    end
  end
 



  if renderer.window.key_down?(GLFW_KEY_SPACE)
    title_panel.position.z = -20
  end


  if renderer.window.key_down?(GLFW_KEY_A)
    drive_ad(tank, JOYSTICK_SENSITIVITY)
    
  end


  if renderer.window.key_down?(GLFW_KEY_D)
    drive_ad(tank, -JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_W)
    drive_ws(tank, JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_S)
    drive_ws(tank, -JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_SPACE)
    drive_ud(tank, JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_LEFT_SHIFT) && tank.position.y>guround_y
    drive_ud(tank, -JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_LEFT)
    rotate_tank(tank, JOYSTICK_SENSITIVITY)
  end


  if renderer.window.key_down?(GLFW_KEY_RIGHT)
    rotate_tank(tank, -JOYSTICK_SENSITIVITY)
  end

  shiny_balls.each_with_index do |ball, i|
    ball.position.y = Math::sin(x * 0.005 + i.to_f) * 3.0 + 4.0
  end
  x += 1


  if y == 10
    ending_panel.position.z = -2.3
  end

  skybox_camera.quaternion.copy(camera.get_world_quaternion)
  renderer.clear
	renderer.render(skybox_scene, skybox_camera)
  renderer.clear_depth
  renderer.render(scene, camera)
  
end
