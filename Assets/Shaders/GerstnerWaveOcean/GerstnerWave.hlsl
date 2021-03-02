#if !defined(GERSTNER_WAVE_INCLUDED)
    #define GERSTNER_WAVE_INCLUDED
    
    #define UNITY_PI 3.1415926
    float3 GerstnerWave(
        float4 wave, float3 p, inout float3 tangent, inout float3 binormal
    )
    {
        float steepness = wave.z;
        float wavelength = wave.w;
        float k = 2 * UNITY_PI / wavelength;
        float c = sqrt(9.8 / k);
        float2 d = normalize(wave.xy) * _Frequency;
        float f = k * (dot(d, p.xz) - c * _Time.y * _Speed);
        float a = steepness / k;
        
        tangent += float3(
            - d.x * d.x * (steepness * sin(f)),
            d.x * (steepness * cos(f)),
            - d.x * d.y * (steepness * sin(f))
        );
        binormal += float3(
            - d.x * d.y * (steepness * sin(f)),
            d.y * (steepness * cos(f)),
            - d.y * d.y * (steepness * sin(f))
        );
        return float3(
            d.x * (a * cos(f)),
            a * sin(f),
            d.y * (a * cos(f))
        );
    }
    
    //Calculating fresnel factor
    float CalculateFresnel(float3 viewDir, float3 normal)
    {
        float R_0 = (_AirRefractiveIndex - _WaterRefractiveIndex) / (_AirRefractiveIndex + _WaterRefractiveIndex);
        R_0 *= R_0;
        return R_0 + (1.0 - R_0) * pow((1.0 - saturate(dot(viewDir, normal))), _FresnelPower);
    }
    
    half3 Highlights(half3 positionWS, half roughness, half3 normalWS, half3 viewDirectionWS)
    {
        Light mainLight = GetMainLight();
        half roughness2 = roughness * roughness;
        half3 halfDir = SafeNormalize(mainLight.direction + viewDirectionWS);
        half NoH = saturate(dot(normalize(normalWS), halfDir));
        half LoH = saturate(dot(mainLight.direction, halfDir));
        // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
        half d = NoH * NoH * (roughness2 - 1) + 1.0001;
        half LoH2 = LoH * LoH;
        half specularTerm = roughness2 / ((d * d) * max(0.1, LoH2) * (roughness + 0.5) * 4);
        specularTerm = min(specularTerm, 10);
        
        return specularTerm * mainLight.color * mainLight.distanceAttenuation;
    }
    
    float SubsurfaceScattering(float3 viewDir, float3 lightDir, float3 normalDir,
    float frontSubsurfaceDistortion, float backSubsurfaceDistortion, float frontSSSIntensity, float thickness)
    {
        //分别计算正面和反面的次表面散射
        float3 frontLitDir = normalDir * frontSubsurfaceDistortion - lightDir;
        float3 backLitDir = normalDir * backSubsurfaceDistortion + lightDir;
        float frontsss = saturate(dot(viewDir, -frontLitDir));
        float backsss = saturate(dot(viewDir, -backLitDir));
        
        float result = saturate(frontsss * frontSSSIntensity + backsss) * thickness;
        return result;
    }

    
#endif