#version 330

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;
layout(location = 2) in vec3 aNormal;
layout(location = 3) in vec2 aTexCoord;

out vec2 texCoord;

// customize
out vec3 vertex_color;
out vec3 Normal;
out vec3 frag_position;
out vec3 light_position;

uniform mat4 um4p;
uniform mat4 um4v;
uniform mat4 um4m;

uniform int ShadingType;
uniform int light_mode;   // 0: direction 1: point 2: spot light
uniform vec3 view_position;
uniform int isEye;

struct Offset
{
    float x;
    float y;
};

uniform Offset eyeOffset;

struct Light
{
    int angle;
    vec3 position;
    vec3 diffuse;
};
uniform Light light;

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

// [TODO] passing uniform variable for texture coordinate offset

void main()
{
    // [TODO]
    
	if(isEye==1){
        texCoord = vec2(aTexCoord.x+eyeOffset.x , aTexCoord.y+eyeOffset.y);
    }
	else{
        texCoord = vec2(aTexCoord.x , aTexCoord.y);
    }
	gl_Position = um4p * um4v * um4m * vec4(aPos, 1.0);
	vertex_color = aColor;
    frag_position = vec3(um4v * um4m * vec4(aPos, 1.0));
    Normal = mat3(transpose(inverse(um4v * um4m))) * aNormal;
    light_position = vec3(um4v * vec4(light.position, 1.0));

    if (ShadingType == 0){
		vec3 ambient = vec3(0.15f, 0.15f, 0.15f)*material.Ka;
		vec3 norm = normalize(Normal);
		vec3 lightspecular= light.diffuse;
        if (light_mode == 0){
            // diffuse
            vec3 light_direction = normalize(-vec3(-1.0f,-1.0f,-1.0f));
            float diff = max(dot(norm,light_direction),0.0);
            vec3 diffuse = light.diffuse*material.Kd*diff;

            // specular
            vec3 view_direction = normalize(view_position - frag_position);
            vec3 halfwayDir = normalize(light_direction + view_direction);
            float spec = pow(max(dot(norm, halfwayDir), 0.0), material.shininess);
            vec3 specular = lightspecular * (spec * material.Ks);
            
			result = ambient + diffuse + specular;
            vertex_color = result;
        }
        if(light_mode==1){
            // ambient
            vec3 ambient = vec3(0.15f, 0.15f, 0.15f) * material.Ka;

            // diffuse
            vec3 light_direction = normalize(light_position - frag_position);
            float diff = max(dot(norm, light_direction), 0.0);
            vec3 diffuse = light.diffuse * material.Kd * diff;

            // specular
            vec3 view_direction = normalize(view_position - frag_position);
            vec3 halfwayDir = normalize(light_direction+view_direction);
            float spec = pow(max(dot(norm, halfwayDir), 0.0), material.shininess);
            vec3 specular = lightspecular * (spec * material.Ks);

            //attenuation
            constant = 0.01;
            linear = 0.8;
            quadratic = 0.1;
            distance = length(light_position - frag_position);
            attenuation = min(1.0f / (constant + linear * distance + quadratic * (distance * distance)), 1);
            result = ambient * attenuation + diffuse * attenuation + specular * attenuation;
            vertex_color = result;
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
            vec3 specular = lightspecular * (spec * material.Ks);

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
            vertex_color = result;
        }
    }
}
