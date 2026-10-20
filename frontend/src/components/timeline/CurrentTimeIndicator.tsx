import React, { useEffect, useState } from 'react';

interface CurrentTimeIndicatorProps {
  pixelsPerHour: number;
}

export const CurrentTimeIndicator: React.FC<CurrentTimeIndicatorProps> = ({ pixelsPerHour }) => {
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 30000); // Update every 30s
    return () => clearInterval(timer);
  }, []);

  const hours = now.getHours();
  const minutes = now.getMinutes();
  const topPosition = (hours + minutes / 60) * pixelsPerHour;

  const timeString = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;

  return (
    <div
      className="absolute inset-x-0 z-30 pointer-events-none flex items-center transition-all duration-500 ease-out"
      style={{ top: `${topPosition}px` }}
    >
      {/* High-voltage Orange Time Pill */}
      <div className="absolute right-1 -top-3 z-40 bg-accent-primary text-white text-[10px] font-mono font-bold px-2 py-0.5 rounded-pill shadow-needle flex items-center gap-1">
        <span className="w-1.5 h-1.5 rounded-full bg-white animate-ping" />
        <span>{timeString}</span>
      </div>

      {/* 1px Glowing Needle Line */}
      <div className="w-full h-[2px] bg-accent-primary shadow-needle" />
    </div>
  );
};
