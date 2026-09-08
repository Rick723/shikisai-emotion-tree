Emotion.transaction do
  [
    { name: "happy", color_code: "#E6A6B6", display_order: 1 },
    { name: "fun", color_code: "#FFD89A", display_order: 2 },
    { name: "relieved", color_code: "#E9A76F", display_order: 3 },
    { name: "grateful", color_code: "#BDE7C5", display_order: 4 },
    { name: "sad", color_code: "#61749B", display_order: 5 },
    { name: "irritated", color_code: "#F28C6B", display_order: 6 },
    { name: "anxious", color_code: "#8585C7", display_order: 7 },
    { name: "other", color_code: "#D6D3CF", display_order: 8 }
  ].each do |attributes|
    emotion = Emotion.find_or_initialize_by(name: attributes.fetch(:name))
    emotion.update!(attributes)
  end
end
