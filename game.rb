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
    File.join File.dirname(__FILE__), "alpha-island_#{path}.png"
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
    map: Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './desert.png').tap { |t| set_repeat(t) },
    normal_map: Mittsu::ImageUtils.load_texture(File.join File.dirname(__FILE__), './desert-normal.png').tap { |t| set_repeat(t) }
  )
)
floor.scale.set(10000.0, 10.0, 10000.0)
floor.position.y = -5.0
scene.add(floor)

loader = Mittsu::OBJMTLLoader.new

things = [
  'Kaktus',
  'collumn',
  'magicrock',
  'rock',
  'skull',
  'stone',
  'tent'
].map do |name|
  [name, loader.load("#{name}/#{name}.obj", "#{name}.mtl").tap do |thing|
    thing.position.set(rand * 10.0 - 5.0, 0.0, rand * 10.0 - 5.0)
    thing.rotation.y = rand * Math::PI * 2.0
    thing.children.grep(Mittsu::Mesh).each { |o| o.material.side = Mittsu::DoubleSide }
    scene.add(thing)
  end]
end.to_h

things['Kaktus'].scale.set(0.1, 0.1, 0.1)
things['skull'].scale.set(0.1, 0.1, 0.1)
things['collumn'].tap { |c|
  c.scale.set(2.0, 2.0, 2.0)
  c.position.y = -1.0
}
things['rock'].tap { |c|
  c.scale.set(2.0, 2.0, 2.0)
  c.position.y = -2.0
}
things['magicrock'].tap { |c|
  c.scale.set(2.0, 2.0, 2.0)
  c.position.y = -2.0
}
things['stone'].tap { |c|
  c.scale.set(5.0, 5.0, 5.0)
  c.position.y = -2.5
}

things.values.each do |thing|
  3.times { thing.clone.tap do |thing2|
    thing2.position.set(rand * 10.0 - 5.0, thing.position.y, rand * 10.0 - 5.0)
    thing2.rotation.set(0.0, rand * Math::PI * 2.0, 0.0, 'XYZ')
    scene.add(thing2)
  end }
end

ball_geometry = Mittsu::SphereGeometry.new(1.0, 16, 16)
ball_material = Mittsu::MeshPhongMaterial.new(env_map: cube_map_texture)
shiny_balls = 10.times.map do
  ball = Mittsu::Mesh.new(ball_geometry, ball_material)
  ball.position.set(rand * 5.0 - 2.5, 0.0, rand * 5.0 - 2.5)
  scale = rand * 0.5 + 0.1
  ball.scale.set(scale, scale, scale)
  scene.add(ball)
  ball
end

object = loader.load('tank.obj', 'tank.mtl')

object.print_tree

tank = Mittsu::Object3D.new
body, wheels, turret, tracks, barrel = object.children.map { |o| o.children.first }
object.children.each do |o|
  o.children.first.material.metal = true
end
[body, wheels, tracks].each do |o|
  tank.add(o)
end

turret.position.set(0.0, 0.17, -0.17)
tank.add(turret)

barrel.position.set(0.0, 0.05, 0.2)
turret.add(barrel)

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

camera.position.z = -3.0
camera.position.y = 2.0
camera.rotation.y = Math::PI
camera.rotation.x = Math::PI/6.0

barrel.add(camera)

renderer.window.on_resize do |width, height|
  renderer.set_viewport(0, 0, width, height)
  camera.aspect = skybox_camera.aspect = width.to_f / height.to_f
  camera.update_projection_matrix
  skybox_camera.update_projection_matrix
end

left_stick = Mittsu::Vector2.new
right_stick = Mittsu::Vector2.new

JOYSTICK_DEADZONE = 0.1
JOYSTICK_SENSITIVITY = 0.05

def rotate_turret(turret, amount)
  turret.rotation.y += amount
end

def turn_tank(tank, turret, amount)
  turret.rotation.y -= amount
  tank.rotation.y += amount
end

def drive_tank(tank, amount)
  tank.translate_z(amount)
end

def lift_barrel(barrel, amount)
  barrel.rotation.x += amount
  if barrel.rotation.x > Math::PI/36.0
    barrel.rotation.x = Math::PI/36.0
  elsif barrel.rotation.x < -Math::PI/6.0
    barrel.rotation.x = -Math::PI/6.0
  end
end

x = 0
renderer.window.run do
  if renderer.window.joystick_present?
    axes = renderer.window.joystick_axes.map do |axis|
      axis.abs < JOYSTICK_DEADZONE ? 0.0 : axis * JOYSTICK_SENSITIVITY
    end
    left_stick.set(axes[0], axes[1])
    right_stick.set(axes[2], axes[3])

    drive_tank(tank, -left_stick.y)
    turn_tank(tank, turret, -left_stick.x)
    rotate_turret(turret, -right_stick.x)
    lift_barrel(barrel, right_stick.y)
  end

  if renderer.window.key_down?(GLFW_KEY_A)
    turn_tank(tank, turret, JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_D)
    turn_tank(tank, turret, -JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_LEFT)
    rotate_turret(turret, JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_RIGHT)
    rotate_turret(turret, -JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_W)
    drive_tank(tank, JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_S)
    drive_tank(tank, -JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_UP)
    lift_barrel(barrel, -JOYSTICK_SENSITIVITY)
  end
  if renderer.window.key_down?(GLFW_KEY_DOWN)
    lift_barrel(barrel, JOYSTICK_SENSITIVITY)
  end

  shiny_balls.each_with_index do |ball, i|
    ball.position.y = Math::sin(x * 0.005 + i.to_f) * 3.0 + 4.0
  end
  x += 1

  skybox_camera.quaternion.copy(camera.get_world_quaternion)

  renderer.clear
	renderer.render(skybox_scene, skybox_camera);
  renderer.clear_depth
  renderer.render(scene, camera)
end
