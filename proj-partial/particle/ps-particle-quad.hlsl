struct Input
{
    float4 position : SV_POSITION;
    float4 color : COLOR;
    float2 texCoord : TEXCOORD0;
    float3 objectPos: POSITIONT;
};

cbuffer Params : register(b0)
{
    float4 Color;
    float Size;
    float3 LightPosition;
    float LightIntensity;
    float LightDecay;
    float RoundShading;
};

float4 psMain(Input input) : SV_TARGET
{
    float2 p = input.texCoord * float2(2.0, 2.0) - float2(1.0, 1.0);
    float d= dot(p, p);
    if (d > 1.0)
         discard;

    // float distanceFromCenter = d;
    // float normalizedDepth = sqrt(1.0 - distanceFromCenter * distanceFromCenter);

    // float sphereRadius = 1;
    // // Current depth
    // float depthOfFragment = sphereRadius * 0.5 * normalizedDepth;
    // //        float currentDepthValue = normalizedViewCoordinate.z - depthOfFragment - 0.0025;
    // //float currentDepthValue = (normalizedViewCoordinate.z - depthOfFragment - 0.0025);

    // //return float4(RoundShading, LightIntensity,1,1);

    // // Calculate the lighting normal for the sphere
    // float3 normal = float3(impostorSpaceCoordinate, normalizedDepth);

    // float3 finalSphereColor = sphereColor;

    // // ambient
    // float lightingIntensity = 0.3 + 0.7 * clamp(dot(lightPosition, normal), 0.0, 1.0);
    // finalSphereColor *= lightingIntensity;

    // // Per fragment specular lighting
    // lightingIntensity  = clamp(dot(lightPosition, normal), 0.0, 1.0);
    // lightingIntensity  = pow(lightingIntensity, 60.0);
    // finalSphereColor += float3(0.4, 0.4, 0.4) * lightingIntensity;

    float3 lightDirection = LightPosition - input.objectPos;

    //return float4(input.objectPos+ 1, 1);
    float2 xy = pow((asin(input.texCoord) * sin(input.texCoord) * 3.1415/4), 1.2);
    float3 normal = normalize(float3(xy,1-length(xy)));
    //return float4(lightDirection.xyz,1);
    float ambient = dot(lightDirection, normal);
    //return float4(xxx, 0,0,1);
    return float4(input.color.rgb * ambient, 1);

    float fallOff = pow(d, RoundShading);
    float4 color = input.color * float4(fallOff,fallOff,fallOff, 1);
    return color;
}
