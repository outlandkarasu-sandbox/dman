#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec2 uv;

uniform mat4 transform;

out vec4 vertexColor;
out vec2 vertexUv;

void main() {
    gl_Position = transform * vec4(position, 1.0f);
    vertexColor = color;
    vertexUv = uv;
}

