#if !defined(TESSELLATION_INCLUDED)
    #define TESSELLATION_INCLUDED
    
    float _TessellationUniform;
    float _TessellationEdgeLength;

    struct TessellationControlPoint
    {
        float4 positionOS: INTERNALTESSPOS;
        float4 color: COLOR;
        float3 normal: NORMAL;
        float2 uv: TEXCOORD0;
    };

    float TessellationEdgeFactor(float3 p0, float3 p1)
    {
        #if defined(_TESSELLATION_EDGE)
            float edgeLength = distance(p0, p1);

            float3 edgeCenter = (p0 + p1) * 0.5;
            float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

            return edgeLength * _ScreenParams.y/ (_TessellationEdgeLength * viewDistance);
        #else
            return _TessellationUniform;
        #endif
    }
    
    
    TessellationControlPoint MyTessellationVertexProgram(a2v v)
    {
        TessellationControlPoint p;
        p.positionOS = v.positionOS;
        p.color = v.color;
        p.normal = v.normal;
        p.uv = v.uv;
        return p;
    }
    
    [domain("tri")]
    [outputcontrolpoints(3)]
    [outputtopology("triangle_cw")]
    [partitioning("fractional_odd")]
    [patchconstantfunc("MyPatchConstantFunction")]
    TessellationControlPoint MyHullProgram(
        InputPatch < TessellationControlPoint, 3 > patch,
        uint id: SV_OutputControlPointID
    )
    {
        return patch[id];
    }
    
    struct TessellationFactors
    {
        float edge[3]: SV_TessFactor;
        float inside: SV_InsideTessFactor;
    };
    
    TessellationFactors MyPatchConstantFunction(
        InputPatch < TessellationControlPoint, 3 > patch
    )
    {
        float3 p0 = mul(unity_ObjectToWorld, patch[0].positionOS).xyz;
	    float3 p1 = mul(unity_ObjectToWorld, patch[1].positionOS).xyz;
	    float3 p2 = mul(unity_ObjectToWorld, patch[2].positionOS).xyz;
        TessellationFactors f;
        f.edge[0] = TessellationEdgeFactor(p1, p2);
        f.edge[1] = TessellationEdgeFactor(p2, p0);
        f.edge[2] = TessellationEdgeFactor(p0, p1);
        f.inside =
		(TessellationEdgeFactor(p1, p2) +
		TessellationEdgeFactor(p2, p0) +
		TessellationEdgeFactor(p0, p1)) * (1 / 3.0);
        return f;
    }
    
    
    [domain("tri")]
    v2f MyDomainProgram(TessellationFactors factors,
    OutputPatch < TessellationControlPoint, 3 > patch,
    float3 barycentricCoordinates: SV_DomainLocation)
    {
        a2v data;
        
        #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z;
        
        
        MY_DOMAIN_PROGRAM_INTERPOLATE(positionOS)
        MY_DOMAIN_PROGRAM_INTERPOLATE(color)
        MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
        MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
        
        return vert(data);
    }
    
    
    
    
    
#endif