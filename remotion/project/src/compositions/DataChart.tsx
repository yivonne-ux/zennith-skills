import React from "react";
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import { FONT_HEADING, FONT_BODY } from "../utils/fonts";
import type { BrandColors, DataPoint, ChartType } from "../utils/types";
import { DEFAULT_BRAND_COLORS } from "../utils/types";
import { fadeIn, staggerDelay } from "../utils/animations";

export type DataChartProps = {
  data: DataPoint[];
  chartType: ChartType;
  title: string;
  brandColors: BrandColors;
  subtitle?: string;
  yAxisLabel?: string;
};

/**
 * DataChart — Animated bar chart or line chart with brand colors.
 * Data animates in with spring physics, staggered per data point.
 * Format: 1920x1080 (16:9 landscape), 30fps, 10s default.
 */
export const DataChart: React.FC<DataChartProps> = ({
  data,
  chartType = "bar",
  title,
  brandColors = DEFAULT_BRAND_COLORS,
  subtitle,
  yAxisLabel,
}) => {
  return (
    <AbsoluteFill
      style={{
        backgroundColor: brandColors.background,
        padding: 60,
      }}
    >
      {/* Title */}
      <ChartTitle
        title={title}
        subtitle={subtitle}
        brandColors={brandColors}
      />

      {/* Chart area */}
      <div
        style={{
          position: "absolute",
          top: 200,
          left: 100,
          right: 100,
          bottom: 80,
        }}
      >
        {chartType === "bar" ? (
          <BarChart
            data={data}
            brandColors={brandColors}
            yAxisLabel={yAxisLabel}
          />
        ) : (
          <LineChart
            data={data}
            brandColors={brandColors}
            yAxisLabel={yAxisLabel}
          />
        )}
      </div>
    </AbsoluteFill>
  );
};

// ─── Title ───────────────────────────────────────────────────────────────────

const ChartTitle: React.FC<{
  title: string;
  subtitle?: string;
  brandColors: BrandColors;
}> = ({ title, subtitle, brandColors }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleOpacity = fadeIn(frame, 0, fps * 0.8);
  const titleY = interpolate(frame, [0, fps * 0.8], [30, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.quad),
  });

  return (
    <div
      style={{
        position: "absolute",
        top: 50,
        left: 100,
        right: 100,
        opacity: titleOpacity,
        transform: `translateY(${titleY}px)`,
      }}
    >
      <h1
        style={{
          fontFamily: FONT_HEADING,
          fontSize: 56,
          fontWeight: 800,
          color: brandColors.accent,
          margin: 0,
          lineHeight: 1.2,
        }}
      >
        {title}
      </h1>
      {subtitle && (
        <p
          style={{
            fontFamily: FONT_BODY,
            fontSize: 28,
            color: `${brandColors.accent}99`,
            margin: "8px 0 0 0",
          }}
        >
          {subtitle}
        </p>
      )}
    </div>
  );
};

// ─── Bar Chart ───────────────────────────────────────────────────────────────

const BarChart: React.FC<{
  data: DataPoint[];
  brandColors: BrandColors;
  yAxisLabel?: string;
}> = ({ data, brandColors, yAxisLabel }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const maxValue = Math.max(...data.map((d) => d.value));
  const barGap = 20;
  const chartStartDelay = Math.round(fps * 0.8);
  const barStagger = Math.round(fps * 0.15);

  // Grid lines
  const gridLines = 5;
  const gridOpacity = fadeIn(frame, Math.round(fps * 0.5), fps * 0.5);

  return (
    <div style={{ width: "100%", height: "100%", position: "relative" }}>
      {/* Y-axis label */}
      {yAxisLabel && (
        <div
          style={{
            position: "absolute",
            left: -60,
            top: "50%",
            transform: "translateY(-50%) rotate(-90deg)",
            fontFamily: FONT_BODY,
            fontSize: 20,
            color: `${brandColors.accent}88`,
            opacity: gridOpacity,
            whiteSpace: "nowrap",
          }}
        >
          {yAxisLabel}
        </div>
      )}

      {/* Grid lines */}
      {Array.from({ length: gridLines + 1 }).map((_, i) => {
        const y = `${(i / gridLines) * 100}%`;
        const gridValue = Math.round(maxValue * (1 - i / gridLines));
        return (
          <div key={i} style={{ position: "absolute", left: 0, right: 0, top: y }}>
            <div
              style={{
                width: "100%",
                height: 1,
                backgroundColor: `${brandColors.accent}15`,
                opacity: gridOpacity,
              }}
            />
            <span
              style={{
                position: "absolute",
                left: -50,
                top: -10,
                fontFamily: FONT_BODY,
                fontSize: 16,
                color: `${brandColors.accent}66`,
                opacity: gridOpacity,
              }}
            >
              {gridValue}
            </span>
          </div>
        );
      })}

      {/* Bars */}
      <div
        style={{
          display: "flex",
          alignItems: "flex-end",
          justifyContent: "center",
          height: "100%",
          gap: barGap,
          paddingBottom: 50,
        }}
      >
        {data.map((point, i) => {
          const delay = chartStartDelay + staggerDelay(i, barStagger);
          const barSpring = spring({
            frame,
            fps,
            delay,
            config: { damping: 15, stiffness: 120 },
          });

          const barHeightPercent = (point.value / maxValue) * 100;
          const barColor = point.color || getBarColor(i, data.length, brandColors);

          // Value label appears after bar animates
          const valueLabelOpacity = interpolate(
            barSpring,
            [0.7, 1],
            [0, 1],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
          );

          return (
            <div
              key={i}
              style={{
                flex: 1,
                maxWidth: 120,
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
              }}
            >
              {/* Value label above bar */}
              <div
                style={{
                  fontFamily: FONT_HEADING,
                  fontSize: 22,
                  fontWeight: 700,
                  color: brandColors.accent,
                  marginBottom: 8,
                  opacity: valueLabelOpacity,
                }}
              >
                {point.value}
              </div>

              {/* Bar */}
              <div
                style={{
                  width: "100%",
                  height: `${barHeightPercent * barSpring}%`,
                  backgroundColor: barColor,
                  borderRadius: "8px 8px 0 0",
                  minHeight: 4,
                  boxShadow: `0 -4px 15px ${barColor}33`,
                }}
              />

              {/* Label below bar */}
              <div
                style={{
                  fontFamily: FONT_BODY,
                  fontSize: 18,
                  fontWeight: 600,
                  color: brandColors.accent,
                  marginTop: 12,
                  textAlign: "center",
                  opacity: barSpring,
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  maxWidth: "100%",
                }}
              >
                {point.label}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

// ─── Line Chart ──────────────────────────────────────────────────────────────

const LineChart: React.FC<{
  data: DataPoint[];
  brandColors: BrandColors;
  yAxisLabel?: string;
}> = ({ data, brandColors, yAxisLabel }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const maxValue = Math.max(...data.map((d) => d.value));
  const chartWidth = 1720; // approximate available width
  const chartHeight = 700; // approximate available height
  const padding = { top: 20, right: 40, bottom: 60, left: 60 };
  const plotWidth = chartWidth - padding.left - padding.right;
  const plotHeight = chartHeight - padding.top - padding.bottom;

  // Points
  const points = data.map((d, i) => ({
    x: padding.left + (i / (data.length - 1)) * plotWidth,
    y: padding.top + plotHeight - (d.value / maxValue) * plotHeight,
    label: d.label,
    value: d.value,
    color: d.color || brandColors.primary,
  }));

  // Path string
  const pathD = points
    .map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`)
    .join(" ");

  // Animate path drawing
  const drawProgress = interpolate(
    frame,
    [fps * 0.8, fps * 3],
    [0, 1],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.out(Easing.quad) },
  );

  // Approximate path length for dash animation
  const approxPathLength = points.reduce((acc, p, i) => {
    if (i === 0) return 0;
    const prev = points[i - 1];
    return acc + Math.sqrt((p.x - prev.x) ** 2 + (p.y - prev.y) ** 2);
  }, 0);

  const strokeDashoffset = approxPathLength * (1 - drawProgress);

  // Grid
  const gridLines = 5;
  const gridOpacity = fadeIn(frame, Math.round(fps * 0.3), fps * 0.5);

  return (
    <svg
      width={chartWidth}
      height={chartHeight}
      viewBox={`0 0 ${chartWidth} ${chartHeight}`}
      style={{ width: "100%", height: "100%" }}
    >
      {/* Grid lines */}
      {Array.from({ length: gridLines + 1 }).map((_, i) => {
        const y = padding.top + (i / gridLines) * plotHeight;
        const gridValue = Math.round(maxValue * (1 - i / gridLines));
        return (
          <g key={i} opacity={gridOpacity}>
            <line
              x1={padding.left}
              y1={y}
              x2={chartWidth - padding.right}
              y2={y}
              stroke={`${brandColors.accent}20`}
              strokeWidth={1}
            />
            <text
              x={padding.left - 15}
              y={y + 5}
              textAnchor="end"
              fontFamily={FONT_BODY}
              fontSize={16}
              fill={`${brandColors.accent}88`}
            >
              {gridValue}
            </text>
          </g>
        );
      })}

      {/* Y-axis label */}
      {yAxisLabel && (
        <text
          x={15}
          y={chartHeight / 2}
          textAnchor="middle"
          fontFamily={FONT_BODY}
          fontSize={18}
          fill={`${brandColors.accent}88`}
          transform={`rotate(-90, 15, ${chartHeight / 2})`}
          opacity={gridOpacity}
        >
          {yAxisLabel}
        </text>
      )}

      {/* Line */}
      <path
        d={pathD}
        fill="none"
        stroke={brandColors.primary}
        strokeWidth={4}
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeDasharray={approxPathLength}
        strokeDashoffset={strokeDashoffset}
      />

      {/* Area fill under line */}
      <path
        d={`${pathD} L ${points[points.length - 1].x} ${padding.top + plotHeight} L ${points[0].x} ${padding.top + plotHeight} Z`}
        fill={`${brandColors.primary}15`}
        strokeDasharray={approxPathLength * 3}
        strokeDashoffset={approxPathLength * 3 * (1 - drawProgress)}
        opacity={drawProgress}
      />

      {/* Data points */}
      {points.map((p, i) => {
        const pointDelay = fps * 0.8 + (i / (data.length - 1)) * fps * 2.2;
        const pointSpring = spring({
          frame,
          fps,
          delay: Math.round(pointDelay),
          config: { damping: 12 },
        });
        const pointScale = pointSpring;

        return (
          <g key={i}>
            {/* Dot */}
            <circle
              cx={p.x}
              cy={p.y}
              r={8 * pointScale}
              fill={brandColors.accent}
              stroke="white"
              strokeWidth={3}
            />

            {/* Value label */}
            <text
              x={p.x}
              y={p.y - 20}
              textAnchor="middle"
              fontFamily={FONT_HEADING}
              fontSize={20}
              fontWeight={700}
              fill={brandColors.accent}
              opacity={pointSpring}
            >
              {p.value}
            </text>

            {/* X-axis label */}
            <text
              x={p.x}
              y={padding.top + plotHeight + 35}
              textAnchor="middle"
              fontFamily={FONT_BODY}
              fontSize={18}
              fontWeight={600}
              fill={brandColors.accent}
              opacity={pointSpring}
            >
              {p.label}
            </text>
          </g>
        );
      })}
    </svg>
  );
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Generate bar color cycling through brand palette */
function getBarColor(
  index: number,
  total: number,
  brandColors: BrandColors,
): string {
  const palette = [
    brandColors.primary,
    brandColors.secondary,
    brandColors.accent,
    brandColors.primary + "CC",
    brandColors.secondary + "CC",
    brandColors.accent + "CC",
  ];
  return palette[index % palette.length];
}
