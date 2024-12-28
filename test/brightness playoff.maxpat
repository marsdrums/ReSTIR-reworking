{
	"patcher" : 	{
		"fileversion" : 1,
		"appversion" : 		{
			"major" : 9,
			"minor" : 0,
			"revision" : 3,
			"architecture" : "x64",
			"modernui" : 1
		}
,
		"classnamespace" : "box",
		"rect" : [ 34.0, 100.0, 1000.0, 780.0 ],
		"gridsize" : [ 15.0, 15.0 ],
		"boxes" : [ 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-12",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 278.0, 1115.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-23",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 278.0, 1152.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"id" : "obj-7",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 642.0, 443.0, 137.0, 22.0 ],
					"text" : "sendoutput filter nearest"
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-2",
					"maxclass" : "jit.pwindow",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_matrix", "" ],
					"patching_rect" : [ 1311.0, 711.0, 477.0, 302.0 ],
					"sync" : 1
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-30",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 190.0, 356.0, 222.0, 22.0 ],
					"text" : "jit.gl.texture @type float32 @rectangle 1"
				}

			}
, 			{
				"box" : 				{
					"fontface" : 0,
					"fontname" : "Arial",
					"fontsize" : 12.0,
					"id" : "obj-29",
					"maxclass" : "jit.fpsgui",
					"mode" : 3,
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "", "" ],
					"patching_rect" : [ 80.0, 790.0, 80.0, 35.0 ]
				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-27",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 234.0, 980.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-28",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 234.0, 1017.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-25",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 234.0, 881.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-26",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 234.0, 918.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"id" : "obj-16",
					"maxclass" : "jit.pwindow",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_matrix", "" ],
					"patching_rect" : [ 186.0, 1398.0, 424.0, 342.0 ],
					"sync" : 1
				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-21",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 790.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-22",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 827.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-19",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 700.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-20",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 737.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-17",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 591.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-18",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 205.0, 628.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "none",
					"id" : "obj-15",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 190.0, 475.0, 293.0, 22.0 ],
					"text" : "jit.gl.slab @dimscale 0.5 0.5 @type float32 @inputs 1",
					"textfile" : 					{
						"text" : "<jittershader name=\"default\">\n\t<description>Default Slab </description>\n\t<param name=\"scale\" type=\"float\" default=\"1.0\" />\n\t<param name=\"tex0\" type=\"int\" default=\"0\" />\n\t<param name=\"modelViewProjectionMatrix\" type=\"mat4\" state=\"MODELVIEW_PROJECTION_MATRIX\" />\n\t<param name=\"textureMatrix0\" type=\"mat4\" state=\"TEXTURE0_MATRIX\" />\n\t<param name=\"position\" type=\"vec3\" state=\"POSITION\" />\n\t<param name=\"texcoord\" type=\"vec2\" state=\"TEXCOORD\" />\n\t<param name=\"color\" type=\"vec4\" state=\"COLOR0\" />\n\t<language name=\"glsl\" version=\"1.5\">\n\t\t<bind param=\"scale\" program=\"fp\" />\n\t\t<bind param=\"tex0\" program=\"fp\" />\n\t\t<bind param=\"modelViewProjectionMatrix\" program=\"vp\" />\n\t\t<bind param=\"textureMatrix0\" program=\"vp\" />\n\t\t<bind param=\"position\" program=\"vp\" />\n\t\t<bind param=\"texcoord\" program=\"vp\" />\n\t\t<bind param=\"color\" program=\"vp\" />\n\t\t<program name=\"vp\" type=\"vertex\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin vec3 position;\n\t\t\tin vec2 texcoord;\n\t\t\tout jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_out;\n\t\t\tuniform mat4 modelViewProjectionMatrix;\n\t\t\tuniform mat4 textureMatrix0;\n\t\t\tuniform vec4 color;\n\t\t\t\n\t\t\tvoid main(void) {\n\t\t\t\tgl_Position = modelViewProjectionMatrix*vec4(position, 1.);\n\t\t\t\tjit_out.texcoord = vec2(textureMatrix0*vec4(texcoord, 0., 1.));\n\t\t\t\tjit_out.color = color;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t\t\n\t\t<program name=\"fp\" type=\"fragment\"  >\n\t\t<![CDATA[\n\t\t\t#version 330 core\n\t\t\t\n\t\t\tin jit_PerVertex {\n\t\t\t\tvec2 texcoord;\n\t\t\t\tvec4 color;\n\t\t\t} jit_in;\n\t\t\tlayout (location = 0) out vec4 outColor;\n\t\t\t\n\t\t\tuniform samplerJit0 tex0;\n\t\t\tuniform float scale;\n\t\t\tvoid main(void) {\n\t\t\t\toutColor = texture(tex0, jit_in.texcoord) * jit_in.color * scale;\n\t\t\t}\n\t\t]]>\n\t\t</program>\n\t</language>\n</jittershader>\n",
						"filename" : "none",
						"flags" : 0,
						"embed" : 1,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"id" : "obj-14",
					"maxclass" : "jit.pwindow",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_matrix", "" ],
					"patching_rect" : [ 824.0, 707.0, 477.0, 302.0 ],
					"sync" : 1
				}

			}
, 			{
				"box" : 				{
					"code" : "out1 = in1.xy/vec(1920, 1080);//in1.b;//sample(in1, vec(norm.x, 0.5 / dim)).b;\r\nout2 = in1.b*0.3;",
					"fontface" : 0,
					"fontname" : "<Monospaced>",
					"fontsize" : 12.0,
					"id" : "obj-13",
					"maxclass" : "jit.gl.pix.codebox",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "jit_gl_texture", "jit_gl_texture", "" ],
					"patching_rect" : [ 824.0, 464.0, 340.0, 200.0 ]
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-11",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_matrix", "" ],
					"patching_rect" : [ 604.0, 303.0, 71.0, 22.0 ],
					"text" : "jit.rgb2luma"
				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.calc_uv_and_luma.jxs",
					"id" : "obj-10",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 190.0, 408.0, 399.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.calc_uv_and_luma.jxs @inputs 1 @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.calc_uv_and_luma.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"id" : "obj-9",
					"maxclass" : "jit.pwindow",
					"numinlets" : 1,
					"numoutlets" : 2,
					"outlettype" : [ "jit_matrix", "" ],
					"patching_rect" : [ 219.5, 280.0, 80.0, 60.0 ],
					"sync" : 1
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-8",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 190.0, 194.0, 148.0, 22.0 ],
					"text" : "output_texture 1, loop 1, 1"
				}

			}
, 			{
				"box" : 				{
					"data" : 					{
						"clips" : [ 							{
								"absolutepath" : "chickens.mp4",
								"filename" : "chickens.mp4",
								"filekind" : "moviefile",
								"id" : "u420002539",
								"loop" : 1,
								"content_state" : 								{
									"loop" : 1
								}

							}
 ]
					}
,
					"drawto" : "",
					"id" : "obj-6",
					"loop" : 1,
					"maxclass" : "jit.playlist",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "jit_gl_texture", "", "dictionary" ],
					"output_texture" : 1,
					"parameter_enable" : 0,
					"patching_rect" : [ 190.0, 231.0, 150.0, 30.0 ],
					"saved_attribute_attributes" : 					{
						"candicane2" : 						{
							"expression" : ""
						}
,
						"candicane3" : 						{
							"expression" : ""
						}
,
						"candicane4" : 						{
							"expression" : ""
						}
,
						"candicane5" : 						{
							"expression" : ""
						}
,
						"candicane6" : 						{
							"expression" : ""
						}
,
						"candicane7" : 						{
							"expression" : ""
						}
,
						"candicane8" : 						{
							"expression" : ""
						}

					}

				}

			}
, 			{
				"box" : 				{
					"filename" : "mm_restir.find_brightest_pixel.jxs",
					"id" : "obj-4",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 2,
					"outlettype" : [ "jit_gl_texture", "" ],
					"patching_rect" : [ 190.0, 516.0, 344.0, 22.0 ],
					"text" : "jit.gl.slab @file mm_restir.find_brightest_pixel.jxs @type float32",
					"textfile" : 					{
						"filename" : "mm_restir.find_brightest_pixel.jxs",
						"flags" : 0,
						"embed" : 0,
						"autowatch" : 1
					}

				}

			}
, 			{
				"box" : 				{
					"id" : "obj-3",
					"maxclass" : "toggle",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "int" ],
					"parameter_enable" : 0,
					"patching_rect" : [ 225.0, 54.0, 24.0, 24.0 ],
					"svg" : ""
				}

			}
, 			{
				"box" : 				{
					"id" : "obj-1",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "jit_matrix", "bang", "" ],
					"patching_rect" : [ 203.0, 128.0, 113.0, 22.0 ],
					"text" : "jit.world @floating 1"
				}

			}
 ],
		"lines" : [ 			{
				"patchline" : 				{
					"destination" : [ "obj-15", 0 ],
					"order" : 1,
					"source" : [ "obj-10", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-4", 1 ],
					"order" : 0,
					"source" : [ "obj-10", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-23", 0 ],
					"source" : [ "obj-12", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-14", 0 ],
					"source" : [ "obj-13", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-2", 0 ],
					"source" : [ "obj-13", 1 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-4", 0 ],
					"source" : [ "obj-15", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-18", 0 ],
					"source" : [ "obj-17", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-19", 0 ],
					"order" : 1,
					"source" : [ "obj-18", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 1 ],
					"order" : 0,
					"source" : [ "obj-18", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-20", 0 ],
					"source" : [ "obj-19", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-21", 0 ],
					"order" : 1,
					"source" : [ "obj-20", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-22", 1 ],
					"order" : 0,
					"source" : [ "obj-20", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-29", 0 ],
					"order" : 2,
					"source" : [ "obj-20", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-22", 0 ],
					"source" : [ "obj-21", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-25", 0 ],
					"order" : 1,
					"source" : [ "obj-22", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-26", 1 ],
					"order" : 0,
					"source" : [ "obj-22", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-13", 0 ],
					"source" : [ "obj-23", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-26", 0 ],
					"source" : [ "obj-25", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-27", 0 ],
					"order" : 1,
					"source" : [ "obj-26", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-28", 1 ],
					"order" : 0,
					"source" : [ "obj-26", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-28", 0 ],
					"source" : [ "obj-27", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-12", 0 ],
					"order" : 1,
					"source" : [ "obj-28", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-16", 0 ],
					"order" : 2,
					"source" : [ "obj-28", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-23", 1 ],
					"order" : 0,
					"source" : [ "obj-28", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-1", 0 ],
					"source" : [ "obj-3", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-10", 0 ],
					"source" : [ "obj-30", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-17", 0 ],
					"order" : 1,
					"source" : [ "obj-4", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-18", 1 ],
					"order" : 0,
					"source" : [ "obj-4", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-30", 0 ],
					"order" : 1,
					"source" : [ "obj-6", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-9", 0 ],
					"order" : 0,
					"source" : [ "obj-6", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-13", 0 ],
					"order" : 0,
					"source" : [ "obj-7", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-28", 0 ],
					"order" : 1,
					"source" : [ "obj-7", 0 ]
				}

			}
, 			{
				"patchline" : 				{
					"destination" : [ "obj-6", 0 ],
					"source" : [ "obj-8", 0 ]
				}

			}
 ],
		"originid" : "pat-4",
		"dependency_cache" : [ 			{
				"name" : "chickens.mp4",
				"bootpath" : "C74:/media/jitter",
				"type" : "mpg4",
				"implicit" : 1
			}
 ],
		"autosave" : 0
	}

}
