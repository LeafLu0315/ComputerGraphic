#version 330

in vec2 texCoord;
// customize
in vec3 vertex_color;
in vec3 frag_position;
in vec3 Normal;
in vec3 light_position;
//
out vec4 fragColor;

// customize
uniform mat4 projection;
uniform int ShadingType;
uniform int light_mode;   // 0: directional  1: point 2: spot light
uniform vec3 view_position;

struct Light
{
    int angle;
    vec3 position;
    vec3 diffuse;
};
uniform Light light;

uniform int isEye;

struct Offset
{
    float x;
    float y;
};
uniform Offset eyeOffset;

struct Material
{
    vec3 Ka;
    vec3 Kd;
    vec3 Ks;
    float shininess;
};
uniform Material material;

vec3 result;
float constant;
float linear;
float quadratic;
float distance;
float attenuation;
float theta;
//

// [TODO] passing texture from main.cpp
// Hint: sampler2D

uniform sampler2D diffuseTexture;

void main()
{
    // [TODO] sampleing from texture
    // Hint: texture
    if (ShadingType == 0){
		//Phong
        fragColor = texture(diffuseTexture, texCoord) * vec4(vertex_color, 1.0);
    }
    else if (ShadingType == 1){
        // Gourand
		vec3 ambient = vec3(0.15f, 0.15f, 0.15f) * material.Ka;
		vec3 norm = normalize(Normal);
		vec3 lightspecular = light.diffuse;
        if (light_mode == 0){
            // diffuse
            vec3 light_direction = normalize(-vec3(-1.0f, -1.0f, -1.0f));
            float diff = max(dot(norm, light_direction), 0.0);
            vec3 diffuse = light.diffuse * material.Kd * diff;

            // specular
            vec3 view_direction = normalize(view_position - frag_position);
            vec3 halfwayDir = normalize(light_direction + view_direction);
            float spec = pow(max(dot(norm, halfwayDir), 0.0), material.shininess);
            vec3 specular = lightspecular * spec * material.Ks;

            result = ambient + diffuse + specular;
            fragColor = texture(diffuseTexture, texCoord) * vec4(result, 1.0f);
        }
        if (light_mode == 1){
            // diffuse
            vec3 light_direction = normalize(light_position - frag_position);
            float diff = max(dot(norm, light_direction), 0.0);
            vec3 diffuse = light.diffuse * material.Kd * diff;

            // specular
            vec3 view_direction = normalize(view_position - frag_position);
            vec3 halfwayDir = normalize(light_direction + view_direction);
            float spec = pow(max(dot(norm, halfwayDir), 0.0), material.shininess);
            vec3 specular = lightspecular * spec * material.Ks;

            //attenuation
            constant = 0.01;
            linear = 0.8;
            quadratic = 0.1;
            distance = length(light_position - frag_position);
            attenuation = min(1.0f / (constant + linear * distance + quadratic * (distance * distance)), 1);

            result = (ambient+diffuse+specular)*attenuation;
            fragColor = texture(diffuseTexture, texCoord) * vec4(result, 1.0f);
        }
        if (light_mode == 2){
            // diffuse
            vec3 light_direction = normalize(light_position - frag_position);
            float diff = max(dot(norm, light_direction), 0.0);
            vec3 diffuse = light.diffuse * material.Kd * diff;

            // specular
            vec3 view_direction = normalize(view_position - frag_position);
            vec3 halfwayDir = normalize(light_direction + view_direction);
            float spec = pow(max(dot(norm, halfwayDir), 0.0), material.shininess);
            vec3 specular = lightspecular * spec * material.Ks;

            //attenuation
            constant = 0.05;
            linear = 0.3;
            quadratic = 0.6;
            distance = length(light_position - frag_position);
            theta = dot(light_direction, normalize(-vec3(0, 0, -1)));
            float spoteffect = pow(max(theta, 0), 50);

            if (theta > cos(radians(light.angle))){
                attenuation = min(1.0f / (constant + linear * distance + quadratic * (distance * distance)), 1);
                result = spoteffect * (ambient * attenuation + diffuse * attenuation + specular * attenuation);
            }
            else{
                result = spoteffect * ambient;
            }
            fragColor = texture(diffuseTexture, texCoord) * vec4(result, 1.0f);
        }
    }
}
