#version 330 core

in vec4 vertexColor;
in vec2 vertexUv;
out vec4 color;

uniform sampler2D textureSampler;

void main() {
    color = vec4(texture(textureSampler, vertexUv).rgb, 1.0f);
}

