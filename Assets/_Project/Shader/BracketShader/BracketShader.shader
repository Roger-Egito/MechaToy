Shader "Bracket/BracketShader"
{
    Properties
    {   
        _Default ("Default", 2D) = "white" {}
        [Toggle]_Transparent ("Transparent", int) = 0
        [Toggle]_AlphaCutout ("Alpha Cutout", int) = 0
        _AlphaCutoutTheshold ("Alpha Cutout Threshold", float) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        _TO ("Scale and Offset", Vector) = (1, 1, 0, 0)
         [Header(General Settings)] [NoScaleOffset] _MainTex ("Main", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Glossiness ("Smoothness", float) = 0
        [NoScaleOffset] _GlossinessMap ("Smoothness Map", 2D) = "white" {}
        _Metallic ("Metallic", float) = 0
        [NoScaleOffset] _MetallicGlossMap ("Metallic Map", 2D) = "white" {}
        [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0, 0, 0, 0)
        [Header(Shading)] _ShadowIntensity ("Shadow Intensity", float) = 0
        _ShadowRamp ("Shadow Ramp", float) = 0
        [Header(Outline)] _Outline ("Outline Strength", float) = 0
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
         [Header(Matcaps)] [NoScaleOffset] _MatCapTex ("MatCap", 2D) = "black" {}
        [NoScaleOffset] _MatCapMask ("MatCap Mask", 2D) = "white" {}
        _MatCapIntensity ("MatCap Intensity", float) = 1
        _MatCapMode ("MatCap Mode", int) = 0
        [NoScaleOffset] _AudioLinkMask ("AudioLink Mask", 2D) = "white" {}
        [Header(Audiolink)] [HDR] _Band0Color("Bass", Color) = (0,0,0,1)
		[HDR] _Band1Color("Low-Mid", Color) = (0,0,0,1)
		[HDR] _Band2Color("High-Mid", Color) = (0,0,0,1)
		[HDR] _Band3Color("Treble", Color) = (0,0,0,1)
        [NoScaleOffset] _WaveformMask ("Waveform Mask", 2D) = "white" {}
        [HDR] _WaveformColor ("Waveform Color Start", Color) = (0,0,0,1)
        [HDR] _WaveformColor2 ("Waveform Color End", Color) = (0,0,0,1)
        _WaveformDirection ("Waveform Direction", Vector) = (1,0,0,0)
    }

    SubShader
    {


        Cull [_Cull]
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Transparent"
        }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

        Pass //idk why this is needed, it fixes the shader being invisible in some cases tho
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase
            #pragma skip_variants SHADOWS_SHADOWMASK SHADOWS_SCREEN SHADOWS_DEPTH SHADOWS_CUBE

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct VertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 color : TEXCOORD2;
                float4 indirect : TEXCOORD3;
                float4 direct : TEXCOORD4;
                SHADOW_COORDS(5)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _Color;
            sampler2D _MainTex;
            float4 _TO;
            int _Transparent;
            float _AlphaCutoutTheshold;
            int _AlphaCutout;

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(VertexOutput i, float facing : VFACE) : SV_Target
            {
                float2 _ScaleOffset = i.uv * _TO.xy;
                _ScaleOffset += _TO.zw;
                half4 textureColor = tex2D(_MainTex, _ScaleOffset);

                if(_Transparent == 1){
                    
                    if(_AlphaCutout){
                        if(_Color.a * textureColor.a < _AlphaCutoutTheshold){
                            discard;
                        }
                    }
                    return float4(0,0,0, _Color.a * textureColor.a);
                }
                return float4(0,0,0, 1);
            }
            ENDCG
        }

        CGPROGRAM
        #pragma surface surf Ramp fullforwardshadows alphatest:transparancy
        #pragma target 3.0
        #include "UnityCG.cginc"
        #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"
        sampler2D _EmissionMap;
        sampler2D _GlossinessMap;
        sampler2D _Default;
        float4 _EmissionColor;
        float4 _Color;
        float _Glossiness;
        float _Metallic;
        sampler2D _MetallicGlossMap;
        float _ShadowIntensity;
        float _ShadowRamp;
        float _Outline;
        float4 _TO;
        sampler2D _MainTex;
        sampler2D _MatCapTex;
        float _MatCapIntensity;
        sampler2D _MatCapMask;
        float4 _Band0Color;
        float4 _Band1Color;
        float4 _Band2Color;
        float4 _Band3Color;
        sampler2D _AudioLinkMask;
        int _MatCapMode;
        float4 _WaveformColor;
        float4 _WaveformColor2;
        sampler2D _WaveformMask;
        float3 _WaveformDirection;
        int _Transparent;
        float _AlphaCutoutTheshold;
        int _AlphaCutout;
        struct Input
        {
            float2 uv_Default;
            float3 worldPos;
            float3 worldRefl;
        };

        
        float3 Fresnel(float power, float3 viewDir, float3 normal)
        {
            return pow(1.0 - saturate(dot(normalize(viewDir), normalize(normal))), power);
        }

        inline float AudioLinkLerp3_g5( int Band, float Delay )
		{
            if(AudioLinkData(ALPASS_GENERALVU + int2( 9, 0 )).rgb.r == 0){
                return 0;
            }
			return AudioLinkLerp( ALPASS_AUDIOLINK + float2( Delay, Band ) ).r;
	    }
        float4 audiolink(int Band, float4 bandcolor)
        {
            float temp_output_38_0 = (Band - 1);
			int Band3_g5 = (int)temp_output_38_0;
			float temp_output_39_0 = 0;
			float Delay3_g5 = (( 0 )?( temp_output_39_0 ):( floor( temp_output_39_0 ) ));
			float localAudioLinkLerp3_g5 = AudioLinkLerp3_g5( Band3_g5 , Delay3_g5 );
			float4 temp_cast_1 = (localAudioLinkLerp3_g5).xxxx;
			float4 temp_output_1_0_g6 = temp_cast_1;
			float4 break5_g6 = temp_output_1_0_g6;
			float band23 = floor( temp_output_38_0 );
			float4 bandColor47 = ( ( band23 == 0.0 ? 1 : float4( 0,0,0,0 ) ) + ( band23 == 1.0 ? 1 : float4( 0,0,0,0 ) ) + ( band23 == 2.0 ? 1 : float4( 0,0,0,0 ) ) + ( band23 == 3.0 ? 1 : float4( 0,0,0,0 ) ) );
		    float4 temp_output_2_0_g6 = bandColor47;
            float4 FinalColor = ( ( ( break5_g6.r * 0.2 ) + ( break5_g6.g * 0.7 ) + ( break5_g6.b * 0.1 ) ) < 0.5 ? ( 2.0 * temp_output_1_0_g6 * temp_output_2_0_g6 ) : ( 1.0 - ( 2.0 * ( 1.0 - temp_output_1_0_g6 ) * ( 1.0 - temp_output_2_0_g6 ) ) ) );
            return FinalColor * bandcolor;
        }
        float4 waveform(float2 iuv)
        {
                if(AudioLinkData(ALPASS_GENERALVU + int2( 9, 0 )).rgb.r == 0){
                    return 0;
                }
                float4 c = Vector(0,0,0,0);
                float audioBands[4] = {0.0, 0.25, 0.5, 0.75};
                float audioThresholds[4] = {0.45, 0.45, 0.45, 0.45};
                float4 intensity = 0;
                uint totalBins = AUDIOLINK_EXPBINS * AUDIOLINK_EXPOCT;
                uint noteno = AudioLinkRemap(iuv.x, 0., 1., AUDIOLINK_4BAND_FREQFLOOR * totalBins, AUDIOLINK_4BAND_FREQCEILING * totalBins);
                float notenof = AudioLinkRemap(iuv.x, 0., 1., AUDIOLINK_4BAND_FREQFLOOR * totalBins, AUDIOLINK_4BAND_FREQCEILING * totalBins);
                float4 spectrum_value_lower  = AudioLinkData(float2(fmod(noteno, 128), (noteno/128)+4.0));
                float4 spectrum_value_higher = AudioLinkData(float2(fmod(noteno+1, 128), ((noteno+1)/128)+4.0));
                intensity = lerp(spectrum_value_lower, spectrum_value_higher, frac(notenof) )* 1;
                float4 segment = 0.;
                for (int i=0; i<4; i++)
                {
                    segment += saturate(0.01 - abs(iuv.x - audioBands[i])) * 1000.;
                }
                float4 threshold = 0;
                float minHeight = 0.186;
                float maxHeight = 0.875;
                int band = 0;
                for (int j=1; j<4; j++)
                {
                    band += (iuv.x > audioBands[j]);
                }
                for (int k=0; k<4; k++)
                {
                    threshold += (band == k) * saturate(0.01 - abs(iuv.y - lerp(minHeight, maxHeight, audioThresholds[k]))) * 1000.;
                }
                threshold = saturate(threshold) * (1. - round((iuv.x % 001) / 001));
                threshold *= (iuv.x > 0);
                float bandIntensity = AudioLinkData(float2(0., (float)band));
                 float rval = clamp(0.01 - iuv.y + intensity.g + 0, 0., 1.);
                rval = min( 1., 1000*rval );
                c = lerp(c, 1, rval);
                return c;
        }

        float2 RotateUVToDirection(float2 uv, float3 direction)
        {
            float angle = atan2(direction.y, direction.x);
            float2x2 rotationMatrix;
            rotationMatrix._m00 = cos(angle);
            rotationMatrix._m01 = -sin(angle);
            rotationMatrix._m10 = sin(angle);
            rotationMatrix._m11 = cos(angle);

            float2 rotatedUV = mul(uv - 0.5, rotationMatrix) + 0.5;

            return rotatedUV;
        }
        void surf(Input IN, inout SurfaceOutput o)
        {
            float2 _ScaleOffset = IN.uv_Default * _TO.xy;
            _ScaleOffset += _TO.zw;
            o.Albedo = tex2D(_MainTex, _ScaleOffset).rgb * _Color;

            half3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos);
            half3 normal = normalize(o.Normal);

            float3 fresnelval = Fresnel(2.5 * _Metallic, viewDir, normal);


            //metallic
            float3 metallic = (UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, IN.worldRefl) * _Glossiness);
            float3 metallicalbedo = lerp(o.Albedo, clamp(metallic * (fresnelval + o.Albedo), 0, 1), clamp((_Metallic * 2) - _Glossiness, 0, 1));
            o.Albedo = (metallicalbedo * tex2D(_MetallicGlossMap, _ScaleOffset)) + (1 - tex2D(_MetallicGlossMap, _ScaleOffset)) * o.Albedo;


            
            //smoothness
            float smooth = _Glossiness * 5000;


            half3 ambientLighting = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, mul(unity_ObjectToWorld, normal), 7.0);


            half3 halfVec = normalize(_WorldSpaceLightPos0 + viewDir); 
            half3 halfVecBaked = normalize(half3(1,1,1) + viewDir); 
            float NdotH = dot(normal, halfVec);
            float NdotHBaked = dot(normal, halfVec);
            float3 smoothnessfx = 0;
            if(_WorldSpaceLightPos0.x == 0 && _WorldSpaceLightPos0.y == 0 && _WorldSpaceLightPos0.z == 0){
                o.Albedo += clamp(clamp(clamp((pow(NdotHBaked, smooth) * ambientLighting.rgb * 100000), 0, 1) * _Glossiness, 0, 1), 0, 1) * tex2D(_GlossinessMap, _ScaleOffset);
            }
            else{
                o.Albedo += clamp(clamp(clamp((pow(NdotH, smooth) * ambientLighting.rgb * 100000), 0, 1) * _Glossiness, 0, 1), 0, 1) * tex2D(_GlossinessMap, _ScaleOffset);
            }


            //MatCap
		    float3 n = normalize(mul(UNITY_MATRIX_V, normal ));
            half2 matcapcoord;
			matcapcoord = (n / 2) + 0.5;
            if(_MatCapMode == 0){
                o.Albedo += tex2D(_MatCapTex, matcapcoord) * _MatCapIntensity * tex2D(_MatCapMask, _ScaleOffset);
            }
            else{
                if(_MatCapMode == 1){
                    o.Albedo *= tex2D(_MatCapTex, matcapcoord) * _MatCapIntensity * tex2D(_MatCapMask, _ScaleOffset);
                }
                else{
                    if(_MatCapMode == 2){
                        o.Albedo = clamp(o.Albedo * (1 - _MatCapIntensity), 0, 1);
                        o.Albedo += tex2D(_MatCapTex, matcapcoord) * _MatCapIntensity * tex2D(_MatCapMask, _ScaleOffset);
                    }
                }
            }


            //emission
            o.Emission = tex2D(_EmissionMap, _ScaleOffset) * _EmissionColor;


            //AudioLink
            o.Emission += clamp((audiolink(1, _Band0Color) + audiolink(2, _Band1Color) + audiolink(3, _Band2Color) + audiolink(4, _Band3Color)) / 4, 0, 1 ) * tex2D(_AudioLinkMask, _ScaleOffset); 
            o.Emission += waveform(RotateUVToDirection(_ScaleOffset, _WaveformDirection.xyz)) * lerp(_WaveformColor, _WaveformColor2, RotateUVToDirection(_ScaleOffset, _WaveformDirection.xyz).y) * tex2D(_WaveformMask, _ScaleOffset);


            o.Albedo = clamp(o.Albedo - (o.Emission.r + o.Emission.g + o.Emission.b), 0, 1);

            o.Alpha = 1;
            if(_Transparent == 1){
                o.Alpha = tex2D(_MainTex, _ScaleOffset).a * _Color.w;
                if(_AlphaCutout){
                    if(o.Alpha < _AlphaCutoutTheshold){
                        discard;
                    }
                }
            }

        }

        half4 LightingRamp(SurfaceOutput s, half3 lightDir, half atten)
        {

            float amount = 8 + _ShadowRamp;


            //realtime
            half NdotL = dot(s.Normal, lightDir);
            half diff = NdotL * 4 * (amount / 2) - (amount / (amount / 2));
            half3 ramp = clamp(step(1, diff) + step(1, diff / amount) + step(1, diff / amount * 2) - 0.5, 0, 1);

            float4 c = Vector(0,0,0,0);


            c.rgb = s.Albedo * atten * _LightColor0.rgb;
            c.rgb *= clamp(ramp + _ShadowIntensity, 0, 1);

    

            //clamp and return
            c = clamp(c, 0, 1);

            if(_Transparent == 1){
                return half4(c.rgb, s.Alpha);
            }
            return half4(c.rgb, 1);
        }
        ENDCG
        Pass
        {
            Tags
            {
                "Queue" = "Geometry"
                "RenderType" = "Transparent"
            }
            Cull Front

            CGPROGRAM
            #pragma vertex vert nofog
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma target 3.0
            float4 _OutlineColor;
            int _Transparent;

            struct VertexInput 
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct VertexOutput 
            {
                float4 pos : SV_POSITION;
            };

            uniform float _Outline;
            float4 _Color;

            VertexOutput vert(VertexInput v) 
            {
                VertexOutput o;
                float4 pos = 0;
                if(_Outline != 0){
                    float expand = (_Outline / 1000) * 4;
                    float4 pos = float4(v.vertex.xyz + v.normal * expand, 1);
                    o.pos = UnityObjectToClipPos(pos);
                }
                else{
                    o.pos = UnityObjectToClipPos(float4(0,0,0,0));
                }
                return o;
            }

            float4 frag(VertexOutput i) : COLOR 
            {
                if(_Transparent == 1){
                    return fixed4(1, 1, 1, _Color.w) * _OutlineColor;
                }
                return fixed4(_OutlineColor.rgb, 1);
            }
            ENDCG
        }
    }
    CustomEditor "BracketShaderGUI"
    FallBack "Standard"
}
