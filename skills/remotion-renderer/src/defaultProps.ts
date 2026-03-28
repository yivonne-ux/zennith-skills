import type { UGCCompositionProps } from "./UGCComposition";

export const defaultUGCProps = {
  "variant_id": "angle4_body_reset_v13",
  "fps": 30,
  "width": 1080,
  "height": 1920,
  "total_duration_s": 50.5,
  "voiceover": "http://localhost:8765/voiceover_v5.mp3",
  "voiceover_volume": 1.0,
  "bgm": "http://localhost:8765/bgm_upbeat.mp3",
  "bgm_volume": 0.25,
  "bgm_fade_out_s": 2.0,
  "watermark": {
    "logo": "mirra-watermark.png",
    "opacity": 0.85
  },
  "enable_transitions": true,
  "sfx_transition": "http://localhost:8765/sfx_whoosh.mp3",
  "sfx_volume": 0.5,
  "film_grain": {
    "enabled": true,
    "intensity": 0.035
  },
  "blocks": [
    {
      "id": "01_A_hook",
      "type": "kol_video",
      "file": "http://localhost:8765/01_A5_Scenario_Christine.mp4",
      "start_s": 0.0,
      "duration_s": 2.8,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "新年过后是不是觉得整个人很重？",
        "headline": "新年后遗症",
        "style": "bold",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "整个人很重",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          0.0,
          0.16,
          0.32,
          0.48,
          0.8,
          0.88,
          1.04,
          1.2,
          1.44,
          1.68,
          1.76,
          1.92,
          2.08,
          2.32,
          2.48
        ],
        "emoji": [
          "😫"
        ]
      },
      "end_card": null,
      "sfx": {
        "file": "http://localhost:8765/sfx_worry.mp3",
        "volume": 0.35,
        "delay_s": 0.3
      }
    },
    {
      "id": "02_A_problem",
      "type": "kol_video",
      "file": "http://localhost:8765/02_A5_Scenario_ChuiEng.mp4",
      "start_s": 2.8,
      "duration_s": 2.0,
      "ken_burns": "none",
      "color_grade": "warm_soft",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "肚子胀胀的，裤子也变紧了。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "肚子胀胀的",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          2.56,
          2.933,
          2.986,
          3.159,
          3.399,
          3.519,
          3.599,
          3.759,
          3.839,
          3.999,
          4.159,
          4.399,
          4.479
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "03_A_bridge",
      "type": "kol_video",
      "file": "http://localhost:8765/03_A1_DishSlideshow_Edra.mp4",
      "start_s": 4.8,
      "duration_s": 3.5,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "fade",
      "light_leak": {
        "position": "top-right",
        "peakOpacity": 0.12
      },
      "text_overlay": {
        "text": "其实你不需要节食，你只需要吃对的东西。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "吃对的东西",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          4.559,
          4.879,
          5.119,
          5.279,
          5.439,
          5.599,
          5.759,
          5.999,
          6.159,
          6.319,
          6.479,
          6.639,
          6.799,
          6.959,
          7.199,
          7.359,
          7.439,
          7.639,
          7.839
        ],
        "emoji": [
          "✨"
        ]
      },
      "end_card": null,
      "sfx": {
        "file": "http://localhost:8765/sfx_reveal.mp3",
        "volume": 0.3,
        "delay_s": 1.5
      }
    },
    {
      "id": "04_I_intro",
      "type": "kol_video",
      "file": "http://localhost:8765/05_A1_DishSlideshow_ChuiEng.mp4",
      "start_s": 8.3,
      "duration_s": 1.5,
      "ken_burns": "drift_right",
      "color_grade": "warm_food",
      "transition": "fade",
      "light_leak": null,
      "text_overlay": {
        "text": "这个就是Mirra配餐。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "Mirra配餐",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          7.999,
          8.079,
          8.319,
          8.479,
          8.639,
          8.692,
          8.745,
          8.798,
          8.878,
          8.958,
          9.278,
          9.358
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "05_I_nutritionist",
      "type": "kol_video",
      "file": "http://localhost:8765/06_I3_PremiumIngredients.mp4",
      "start_s": 9.8,
      "duration_s": 3.7,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "它是营养师专业调配的，每一餐不到500卡。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "营养师专业调配",
            "color": "#E68A7E",
            "scale": 1.15
          },
          {
            "text": "不到500卡",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          9.518,
          9.678,
          9.838,
          9.998,
          10.238,
          10.478,
          10.678,
          10.878,
          11.118,
          11.278,
          11.358,
          11.478,
          11.598,
          11.758,
          12.078,
          12.278,
          12.478,
          12.611,
          12.744,
          12.877,
          12.957
        ],
        "emoji": [
          "👩‍⚕️"
        ]
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "06_I_kitchen",
      "type": "kol_video",
      "file": "http://localhost:8765/18_I1_KitchenBTS_Fusilli.mp4",
      "start_s": 13.5,
      "duration_s": 3.0,
      "ken_burns": "drift_left",
      "color_grade": "cool_clean",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "而且最厉害的是，它有超过50种异国风味的menu，",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "50种异国风味",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          13.157,
          13.277,
          13.597,
          13.757,
          13.957,
          13.997,
          14.197,
          14.397,
          14.477,
          14.557,
          14.797,
          14.997,
          15.197,
          15.397,
          15.597,
          15.837,
          15.997,
          16.157,
          16.317,
          16.477,
          16.557,
          16.637,
          16.717,
          16.797,
          16.877
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "07_I_breather",
      "type": "kol_video",
      "file": "http://localhost:8765/11_A1_DishSlideshow_Vivian.mp4",
      "start_s": 16.5,
      "duration_s": 1.5,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "fade",
      "light_leak": {
        "position": "center",
        "peakOpacity": 0.1
      },
      "text_overlay": null,
      "end_card": null,
      "sfx": null
    },
    {
      "id": "08_I_variety",
      "type": "kol_video",
      "file": "http://localhost:8765/16_A1_DishSlideshow_ElaineHow.mp4",
      "start_s": 18.0,
      "duration_s": 1.8,
      "ken_burns": "drift_right",
      "color_grade": "warm_food",
      "transition": "fade",
      "light_leak": null,
      "text_overlay": {
        "text": "所以你每天吃到的都不一样。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "都不一样",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          17.037,
          17.197,
          17.357,
          17.517,
          17.677,
          17.917,
          18.077,
          18.277,
          18.477,
          18.677,
          18.877,
          18.997,
          19.117
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "09_I_fresh",
      "type": "kol_video",
      "file": "http://localhost:8765/07_I4_PackingLine.mp4",
      "start_s": 19.8,
      "duration_s": 2.5,
      "ken_burns": "slow_zoom_in",
      "color_grade": "cool_clean",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "全部都是当天新鲜现做的，",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "当天新鲜现做",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          19.277,
          19.437,
          19.597,
          19.757,
          19.917,
          20.157,
          20.477,
          20.717,
          20.957,
          21.197,
          21.357,
          21.437
        ],
        "emoji": [
          "🥗"
        ]
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "10_I_delivery",
      "type": "kol_video",
      "file": "http://localhost:8765/20_I5_Delivery.mp4",
      "start_s": 22.3,
      "duration_s": 2.5,
      "ken_burns": "none",
      "color_grade": "warm_soft",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "然后直接送到你的office或者你家。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "直接送到",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          21.57,
          21.703,
          21.836,
          22.036,
          22.236,
          22.396,
          22.476,
          22.596,
          22.716,
          22.796,
          22.876,
          22.956,
          23.036,
          23.116,
          23.196,
          23.356,
          23.516,
          23.756,
          23.916
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "11_D_taste",
      "type": "kol_video",
      "file": "http://localhost:8765/04_D1_EatingScene_Carolyn.mp4",
      "start_s": 24.8,
      "duration_s": 2.8,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "fade",
      "light_leak": {
        "position": "top-left",
        "peakOpacity": 0.12
      },
      "text_overlay": {
        "text": "吃起来真的很饱，而且味道很好。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "真的很饱",
            "color": "#E68A7E",
            "scale": 1.15
          },
          {
            "text": "味道很好",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          23.996,
          24.476,
          24.596,
          24.716,
          24.876,
          25.036,
          25.276,
          25.716,
          25.782,
          25.848,
          25.914,
          26.074,
          26.234,
          26.474,
          26.634
        ],
        "emoji": [
          "😋"
        ]
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "12_D_convenient",
      "type": "kol_video",
      "file": "http://localhost:8765/09_D3_UnboxReveal.mp4",
      "start_s": 27.6,
      "duration_s": 3.3,
      "ken_burns": "none",
      "color_grade": "warm_soft",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "不用自己煮，不用自己想，打开就可以吃了。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "打开就可以吃了",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          26.754,
          26.874,
          27.034,
          27.194,
          27.354,
          27.674,
          27.714,
          27.754,
          27.994,
          28.154,
          28.314,
          28.474,
          28.554,
          28.794,
          29.034,
          29.194,
          29.354,
          29.514,
          29.674,
          29.754
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "13_D_results",
      "type": "kol_video",
      "file": "http://localhost:8765/13_A3_GoodReaction_Jessica.mp4",
      "start_s": 30.9,
      "duration_s": 3.0,
      "ken_burns": "none",
      "color_grade": "warm_soft",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "很多姐妹吃了一个星期就开始有感觉，",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "一个星期",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          30.074,
          30.154,
          30.234,
          30.394,
          30.714,
          30.794,
          30.954,
          31.114,
          31.274,
          31.514,
          31.754,
          31.914,
          32.114,
          32.314,
          32.394,
          32.634,
          32.874
        ],
        "emoji": [
          "💪"
        ]
      },
      "end_card": null,
      "sfx": {
        "file": "http://localhost:8765/sfx_success.mp3",
        "volume": 0.3,
        "delay_s": 1.0
      }
    },
    {
      "id": "14_D_lighter",
      "type": "kol_video",
      "file": "http://localhost:8765/12_D1_EatingScene_Aurelia.mp4",
      "start_s": 33.9,
      "duration_s": 3.0,
      "ken_burns": "slow_zoom_in",
      "color_grade": "warm_food",
      "transition": "none",
      "light_leak": null,
      "text_overlay": {
        "text": "肚子没有那么胀了，整个人也轻了很多。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "轻了很多",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          32.954,
          33.234,
          33.354,
          33.514,
          33.674,
          33.794,
          33.914,
          34.234,
          34.314,
          34.394,
          34.554,
          34.714,
          34.874,
          35.194,
          35.354,
          35.514,
          35.714,
          35.914
        ],
        "emoji": null
      },
      "end_card": null,
      "sfx": null
    },
    {
      "id": "15_Act_cta",
      "type": "kol_video",
      "file": "http://localhost:8765/14_A6_Results_ChuiEng.mp4",
      "start_s": 36.9,
      "duration_s": 4.0,
      "ken_burns": "none",
      "color_grade": "warm_soft",
      "transition": "fade",
      "light_leak": null,
      "text_overlay": {
        "text": "直接WhatsApp我们就可以了。KL跟Selangor都有外送哦。",
        "headline": null,
        "style": "normal",
        "position": "lower_third",
        "emphasis": [
          {
            "text": "WhatsApp我们",
            "color": "#E68A7E",
            "scale": 1.15
          }
        ],
        "outline": true,
        "char_timestamps": [
          42.31,
          42.47,
          42.63,
          42.67,
          42.71,
          42.75,
          42.79,
          42.83,
          42.87,
          42.91,
          42.95,
          43.11,
          43.27,
          43.43,
          43.55,
          43.67,
          43.75,
          43.91,
          44.07,
          44.23,
          44.39,
          44.443,
          44.496,
          44.549,
          44.602,
          44.655,
          44.708,
          44.828,
          44.948,
          45.108,
          45.268,
          45.428,
          45.668,
          45.748
        ],
        "emoji": [
          "📱"
        ]
      },
      "end_card": null,
      "sfx": {
        "file": "http://localhost:8765/sfx_message.mp3",
        "volume": 0.4,
        "delay_s": 0.5
      }
    },
    {
      "id": "16_Act_endcard",
      "type": "end_card",
      "file": "http://localhost:8765/15_Act6_EndCard.mp4",
      "start_s": 40.9,
      "duration_s": 8.0,
      "ken_burns": "none",
      "color_grade": "none",
      "transition": "slide_up",
      "light_leak": null,
      "text_overlay": null,
      "end_card": null,
      "sfx": null
    },
    {
      "id": "17_logo_sting",
      "type": "logo_sting",
      "file": "mirra-logo-ending.mp4",
      "start_s": 48.9,
      "duration_s": 1.6,
      "ken_burns": "none",
      "color_grade": "none",
      "transition": "fade",
      "light_leak": null,
      "text_overlay": null,
      "end_card": null,
      "sfx": null
    }
  ],
  "bgm_end_s": 48.9,
  "text_style_preset": "jianying_outline"
} as unknown as UGCCompositionProps;
