Shader "Custom/GerstnerWaveOcean"
{
    Properties
    {
        [Header(BaseShading)]
        _BaseMap ("Example Texture", 2D) = "white" { }
        [HDR]_BaseColor ("Base Colour", Color) = (0, 0.66, 0.73, 1)
        _WaterFogColor ("Water Fog Colour", Color) = (0, 0.66, 0.73, 1)
        _FogDensity ("Fog Density", range(0, 1)) = 0.1
        _NormalMap ("Normal Map", 2D) = "white" { }
        _NormalScale ("Normal Scale", Range(0, 1)) = 0.1
        _Shininess ("High Light Roughness", Range(0, 0.1)) = 0.01
        [Space(20)]
        [Header(Reflection)]
        _Skybox ("Skybox", Cube) = "white" { }
        [Header(Refractive)]
        _AirRefractiveIndex ("Air Refractive Index", Float) = 1.0
        _WaterRefractiveIndex ("Water Refractive Index", Float) = 1.333
        _FresnelPower ("Fresnel Power", Range(0.1, 50)) = 5
        _RefractionStrength ("Refraction Strength", Range(0, 1)) = 0.1
        
        [Space(20)]
        [Header(SSS)]
        _FrontSubsurfaceDistortion ("Front Subsurface Distortion", Range(0, 1)) = 0.5
        _BackSubsurfaceDistortion ("Back Subsurface Distortion", Range(0, 1)) = 0.5
        _FrontSSSIntensity ("Front SSS Intensity", float) = 0.2
        _HeightCorrection ("SSS Height Correction", float) = 6
        
        [Space(20)]
        [Header(Foam)]
        _FoamIntensity ("Foam Intensity", float) = 0.5
        _FoamNoiseTex ("Foam Noise", 2D) = "white" { }
        
        [Space(20)]
        [Header(Caustic)]
        _CausticIntensity ("Caustic Intensity", float) = 0.5
        _CausticTex ("Caustic Texture", 2D) = "white" { }
        _Caustics_Speed ("Caustics Speed,(x,y)&(z,w)", Vector) = (1, 1, -1, -1)
        
        [Space(20)]
        [Header(Waves)]
        _Speed ("Speed", float) = 0.2
        _Frequency ("Frequency", float) = 2
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
        _WaveB ("Wave B", Vector) = (0, 1, 0.25, 20)
        _WaveC ("Wave C", Vector) = (1, 1, 0.15, 10)
        _WaveD ("Wave D", Vector) = (0, 1, 0.25, 20)
        _WaveE ("Wave E", Vector) = (1, 1, 0.15, 10)
        _WaveF ("Wave F", Vector) = (0, 1, 0.25, 20)
        _WaveG ("Wave G", Vector) = (1, 1, 0.15, 10)
        _WaveH ("Wave H", Vector) = (0, 1, 0.25, 20)
        _WaveI ("Wave I", Vector) = (1, 1, 0.15, 10)
        _WaveJ ("Wave J", Vector) = (1, 1, 0.15, 10)
        _WaveK ("Wave K", Vector) = (1, 1, 0.15, 10)
        _WaveL ("Wave L", Vector) = (1, 1, 0.15, 10)
        [Space(20)]
        [Header(Tessellation)]
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [Toggle(_TESSELLATION_EDGE)]_TESSELLATION_EDGE ("TESSELLATION EDGE", float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "RenderQueue" = "Transparent" }
        
        ZWrite Off
        ZTest On
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST, _FoamNoiseTex_ST, _CausticTex_ST;
        float4 _BaseColor, _WaterFogColor, _Caustics_Speed;
        float4 _NormalMap_ST;
        float4 _WaveA, _WaveB, _WaveC, _WaveD, _WaveE, _WaveF, _WaveG, _WaveH, _WaveI, _WaveJ, _WaveK, _WaveL;
        float _Speed, _Frequency, _NormalScale, _AirRefractiveIndex, _WaterRefractiveIndex, _FresnelPower;
        float _RefractionStrength, _FogDensity, _Shininess, _FrontSubsurfaceDistortion, _BackSubsurfaceDistortion;
        float _FrontSSSIntensity, _HeightCorrection, _FoamIntensity, _CausticIntensity;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Name "Example"
            Tags { "LightMode" = "UniversalForward" }
            
            ZWrite off
            
            HLSLPROGRAM
            
            #include "GerstnerWave.hlsl"
            #pragma target 4.6
            
            #pragma vertex MyTessellationVertexProgram
            #pragma fragment frag
            #pragma hull MyHullProgram
            #pragma domain MyDomainProgram
            #pragma shader_feature _TESSELLATION_EDGE
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            
            
            struct a2v
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float4 color: COLOR;
            };
            
            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: TEXCOORD1;
                float3 positionWS: TEXCOORD2;
                float3 tangentWS: TEXCOORD3;
                float4 scrPos: TEXCOORD4;
                float heightOS: TEXCOORD5;
                float fogFactor: TEXCOORD6;
                float4 color: COLOR;
            };
            
            TEXTURECUBE(_Skybox);
            SAMPLER(sampler_Skybox);
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            TEXTURE2D(_FoamNoiseTex);
            SAMPLER(sampler_FoamNoiseTex);
            TEXTURE2D(_CausticTex);
            SAMPLER(sampler_CausticTex);
            
            
            v2f vert(a2v v)
            {
                v2f o;
                float3 tangent = float3(1, 0, 0);
                float3 binormal = float3(0, 0, 1);
                float3 p = v.positionOS;
                
                p += GerstnerWave(_WaveA, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveB, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveC, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveD, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveE, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveF, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveG, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveH, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveI, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveJ, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveK, v.positionOS.xyz, tangent, binormal);
                p += GerstnerWave(_WaveL, v.positionOS.xyz, tangent, binormal);
                
                
                o.heightOS = p.y;
                float3 normal = normalize(cross(binormal, tangent));
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(p);
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normal, float4(tangent, 1));
                o.normalWS = vertexNormalInput.normalWS;
                o.tangentWS = vertexNormalInput.tangentWS;
                o.scrPos = ComputeScreenPos(o.positionCS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.fogFactor = ComputeFogFactor(positionInputs.positionCS.z);

                return o;
            }
            
            #include "MyTessellation.hlsl"
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            
            half4 frag(v2f i): SV_Target
            {
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS.xyz);
                Light light = GetMainLight(shadowCoord);
                float3 normalWS = normalize(i.normalWS);
                //-----------normal-----------
                real3x3 TtoW = CreateTangentToWorld(i.normalWS, i.tangentWS, 1);
                float4 normalTS = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv * _NormalMap_ST.xy);
                normalTS.xyz = normalize(UnpackNormal(normalTS));
                normalWS = lerp(normalWS, normalize(TransformTangentToWorld(normalTS, TtoW)), _NormalScale);
                normalWS = SafeNormalize(normalWS);
                
                //-----------reflection-----------
                float3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - i.positionWS.xyz);
                float3 reflectDir = reflect(-viewDirectionWS, normalWS);
                float4 reflectCol = SAMPLE_TEXTURECUBE(_Skybox, sampler_Skybox, reflectDir);
                
                //-----------refraction-----------
                float2 scrPos = i.scrPos / i.scrPos.w;
                half depth = SampleSceneDepth(scrPos);
                depth = LinearEyeDepth(depth, _ZBufferParams);
                //ClipPos.w = -ViewPos.z
                float surfaceDepth = i.scrPos.w;
                float depthDiffer = depth - surfaceDepth;
                
                float2 uvOffset = normalWS.xz * _RefractionStrength * saturate(depthDiffer);
                float2 offsetPos = scrPos + uvOffset;
                float offsetPosDepth = SampleSceneDepth(offsetPos);
                offsetPosDepth = LinearEyeDepth(offsetPosDepth, _ZBufferParams);
                offsetPos = scrPos + uvOffset * step(surfaceDepth, offsetPosDepth);
                
                float4 refractCol = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, offsetPos);
                //Caustic
                float depthFactor = depth / surfaceDepth;
                float3 underPos = (i.positionWS - GetCameraPositionWS()) * depthFactor + GetCameraPositionWS();
                float2 causticSampler = (underPos.xy + underPos.xz + underPos.yz) / 100 * _CausticTex_ST.xy;
                float4 caustic1 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticSampler + _Caustics_Speed.xy * _Time.y/30);
                float4 caustic2 = SAMPLE_TEXTURE2D(_CausticTex, sampler_CausticTex, causticSampler + _Caustics_Speed.zw * _Time.y/30); 
                float4 caustic = min(caustic1, caustic2);

                //-----------fog-----------
                float offsetDepthDiffer = surfaceDepth > offsetPosDepth ? depthDiffer: offsetPosDepth - surfaceDepth;
                float fogFactor = saturate(1 - exp(-offsetDepthDiffer * _FogDensity / 10)) * light.shadowAttenuation;
                float4 waterCol = lerp(_WaterFogColor, _BaseColor, fogFactor);
                refractCol = lerp(waterCol, waterCol * refractCol, saturate(fogFactor));
                refractCol += caustic * pow((1 - saturate(fogFactor)), 10);
                
                //-----------specular-----------
                float3 halfDir = SafeNormalize(viewDirectionWS + normalize(light.direction));
                float3 specular = Highlights(i.positionWS, _Shininess, normalWS, viewDirectionWS);
                specular *= light.shadowAttenuation;
                
                //-----------SSS-----------
                float SSSValue = SubsurfaceScattering(viewDirectionWS, light.direction, normalWS, _FrontSubsurfaceDistortion,
                _BackSubsurfaceDistortion, _FrontSSSIntensity, saturate(i.heightOS - _HeightCorrection));
                SSSValue *= light.shadowAttenuation;
                
                
                float fresnel = CalculateFresnel(viewDirectionWS, normalWS);
                float4 scatterCol = lerp(refractCol, reflectCol, saturate(fresnel));
                
                
                float3 shading = scatterCol.rgb + specular + SSSValue * light.color;
                
                //-----------foam-----------
                float foamOffset = SAMPLE_TEXTURE2D(_FoamNoiseTex, sampler_FoamNoiseTex, i.uv * _FoamNoiseTex_ST.xy + _Time.y).x;
                shading = lerp(shading, float3(0.8, 0.8, 0.8), pow(saturate(_FoamIntensity * foamOffset -depthDiffer) * 2, 3) * saturate(depthDiffer));
                
                shading = MixFog(shading.rgb, i.fogFactor);
                return float4(shading.rgb, 1);
            }
            ENDHLSL
            
        }
    }
}