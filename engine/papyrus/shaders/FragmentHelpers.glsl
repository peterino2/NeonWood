float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}

float contour(float dist, float edge, float width) {
  return clamp(smoothstep(edge - width, edge + width, dist), 0.0, 1.0);
}

float getSample(vec2 texCoord, float edge, float width) {
  return contour(texture(tex, texCoord).r, edge, width);
}

bool scissor(vec2 position, vec2 topleft, vec2 size)
{
    if(position.x >= topleft.x && position.x <= topleft.x + size.x &&
       position.y >= topleft.y && position.y <= topleft.y + size.y )
    {
        return true;
    }

    return false;
}

bool rect(vec2 position, vec2 topleft, vec2 size)
{
    if(position.x >= topleft.x && position.x <= topleft.x + size.x &&
       position.y >= topleft.y && position.y <= topleft.y + size.y )
    {
        return true;
    }

    return false;
}

bool somewhatEqual(float left, float right)
{
    return distance(left, right) < 1.0;
}
