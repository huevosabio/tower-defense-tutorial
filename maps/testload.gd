extends TextureRect

# Called when the node enters the scene tree for the first time.
func _ready():
	var img_url = "https://storage.googleapis.com/isolate-dev-hot-rooster_toolkit_bucket/github_110602490/53fff3d255ee4d1d86f708064cc9d8ce_1320bad88df44a1ab0f8809b5f4791c5.png?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=gke-service-account%40isolate-dev-hot-rooster.iam.gserviceaccount.com%2F20240512%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20240512T180305Z&X-Goog-Expires=604800&X-Goog-SignedHeaders=host&X-Goog-Signature=a9a2da8bfcd9ae9e63f01dc107fa0814c118ae2411a361562579ad1b8894f504ff0224e448cdfe1e969ba83eb89e0a6ac0b3f42435a384f22894519aac94ba2bf6100596973bffaa1b71a894912a90eadb0c6de9edf0c9fb5d819583ae05e30f30919ed0a01a0a16c69624cd8d569fe97591a532175248cf638b497d1a73ccc332a894589136c4b45a25f1ab5fc912150143ed294c5a077a381a70fd14ce40db9fccb3765f73668eb98ffdb264f13dd5676ddf2f0a6ee229b8a4517dfa80c0f13bd9d0d6b8106600e34b4d0e6ce71969a4073ae9efcffc6df2e3f7f89bab2f12bba0c179b8e47d79ebffcb30fe60e46ca81ce6ee7a708f64b936be1be2fb07e7"
	var http_img_request = HTTPRequest.new() # Create a new HTTPRequest node if it's not already attached.
	add_child(http_img_request) # Add it as a child if not already in the scene tree.
	http_img_request.request_completed.connect(_finish_set_image)
	http_img_request.request(img_url)

func _finish_set_image(result, response_code, headers, body):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")

	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)

	new_texture.set_size_override(Vector2(241,397))
	
	print("oldddtexture")
	print(texture)
	print("newwwtexture")
	print(new_texture)
	print("imageeee")
	print(image)
	texture = new_texture
