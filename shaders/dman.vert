#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec4 color;

out vec4 vertexColor;

void main() {
    gl_Position.xyz = position;
    gl_Position.w = 1.0;
    vertexColor = color;
}

