﻿Shader "Hidden/Wireframe"
{
	Properties
	{
		_LineColor ("LineColor", Color) = (1,1,1,1)
		_FillColor ("FillColor", Color) = (0.1411,0.6313,0.917,0)
		_WireThickness ("Wire Thickness", RANGE(0, 800)) = 600
		[KeywordEnum(UV0, UV1, UV2)] UVChannel("UV channel", Float) = 0
 }

	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			// Wireframe shader based on the the following
			// http://developer.download.nvidia.com/SDK/10/direct3d/Source/SolidWireframe/Doc/SolidWireframe.pdf

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile UVCHANNEL_UV0 UVCHANNEL_UV1 UVCHANNEL_UV2
			#include "UnityCG.cginc"

			float _WireThickness;

			struct appdata
			{
				float4 vertex : POSITION;
#ifdef UVCHANNEL_UV0
				float2 uv : TEXCOORD0;
#elif UVCHANNEL_UV1
				float2 uv : TEXCOORD1;
#elif UVCHANNEL_UV2
				float2 uv : TEXCOORD2;
#else
				float2 uv: TEXCOORD0;
#endif
			};

			struct v2g
			{
				float4 projectionSpaceVertex : SV_POSITION;
				float4 worldSpacePosition : TEXCOORD1;
			};

			struct g2f
			{
				float4 projectionSpaceVertex : SV_POSITION;
				float4 worldSpacePosition : TEXCOORD0;
				float4 dist : TEXCOORD1;
			};

			
			v2g vert (appdata v)
			{
				v2g o;
//				UNITY_SETUP_INSTANCE_ID(v);
//				UNITY_INITIALIZE_OUTPUT(v2g, o);
				o.projectionSpaceVertex = UnityObjectToClipPos(float4(v.uv.x, 0.0, v.uv.y, 1.0));
				o.worldSpacePosition = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			[maxvertexcount(3)]
			void geom(triangle v2g i[3], inout TriangleStream<g2f> triangleStream)
			{
				float2 p0 = i[0].projectionSpaceVertex.xy / i[0].projectionSpaceVertex.w;
				float2 p1 = i[1].projectionSpaceVertex.xy / i[1].projectionSpaceVertex.w;
				float2 p2 = i[2].projectionSpaceVertex.xy / i[2].projectionSpaceVertex.w;

				float2 edge0 = p2 - p1;
				float2 edge1 = p2 - p0;
				float2 edge2 = p1 - p0;

				// To find the distance to the opposite edge, we take the
				// formula for finding the area of a triangle Area = Base/2 * Height, 
				// and solve for the Height = (Area * 2)/Base.
				// We can get the area of a triangle by taking its cross product
				// divided by 2.  However we can avoid dividing our area/base by 2
				// since our cross product will already be double our area.
				float area = abs(edge1.x * edge2.y - edge1.y * edge2.x);
				float wireThickness = 800 - _WireThickness;

				g2f o;
				o.worldSpacePosition = i[0].worldSpacePosition;
				o.projectionSpaceVertex = i[0].projectionSpaceVertex;
				o.dist.xyz = float3( (area / length(edge0)), 0.0, 0.0) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				triangleStream.Append(o);

				o.worldSpacePosition = i[1].worldSpacePosition;
				o.projectionSpaceVertex = i[1].projectionSpaceVertex;
				o.dist.xyz = float3(0.0, (area / length(edge1)), 0.0) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				triangleStream.Append(o);

				o.worldSpacePosition = i[2].worldSpacePosition;
				o.projectionSpaceVertex = i[2].projectionSpaceVertex;
				o.dist.xyz = float3(0.0, 0.0, (area / length(edge2))) * o.projectionSpaceVertex.w * wireThickness;
				o.dist.w = 1.0 / o.projectionSpaceVertex.w;
				triangleStream.Append(o);
			}

			uniform fixed4 _LineColor;
			uniform fixed4 _FillColor;

			fixed4 frag (g2f i) : SV_Target
			{
				float minDistanceToEdge = min(i.dist[0], min(i.dist[1], i.dist[2])) * i.dist[3];

				// Early out if we know we are not on a line segment.
				if(minDistanceToEdge > 0.9)
				{
					return _FillColor;
				}

				return _LineColor;
			}
			ENDCG
		}
	}
}