###########
# Image preparation
#
# TODO
# - scale
# - co-registration

"""
    crop(img, topleft, bottomright)

Crops an image.
"""
function crop(img, topleft, bottomright)
    i1, i2 = indices(img)
    img[max(topleft[1],i1[1]):min(bottomright[1],i1[end]),
        max(topleft[2],i2[1]):min(bottomright[2],i2[end])]
end
crop(img, left, right, down, up) = img[1+left:end-right,1+down:end-up]
"""
    thin(img,step)

Thin an image
"""
thin(img,step) = img[1:step:end,1:step:end]


"""
    rotate_n_crop(img, ep::ExpPics; verbose=false)
    rotate_n_crop(img, p1::Tuple{Int,Int}, p2::Tuple{Int,Int},
                  halfheight::Integer; verbose=false)

Rotates the image such that the line through p1 and p2 is horizontal.
It then crops it such that the width spans p1 and p2 and the
height is 2x halfheight.

Notes: needs to be in sync with ExpPics defaults definition.
"""
rotate_n_crop(img, ep::ExpPics; verbose=false) =
    rotate_n_crop(img, ep.p1, ep.p2, ep.halfheight, verbose=verbose)
function rotate_n_crop(img, p1::Tuple{Int,Int}, p2::Tuple{Int,Int}, halfheight::Integer; verbose=false)
    @assert p1[2]<=p2[2] "point p1 must be on the left of p2"
    angle = atan2(p2[1]-p1[1], p2[2]-p1[2])
    len = round(Int, sqrt( (p2[1]-p1[1])^2 + (p2[2]-p1[2])^2 ))
    tfm = recenter(RotMatrix(-angle), [p1...])
    img2 = warp(img, tfm);
    topleft = (p1[1]-halfheight, p1[2])
    bottomright = (p1[1]+halfheight, p1[2]+len)
    if verbose
        guidict = imshow(img2);
        annotate!(guidict, AnnotationPoint(p1[2], p1[1], shape='x', size=20, linewidth=2));
        annotate!(guidict, AnnotationBox(topleft[2], topleft[1], bottomright[2], bottomright[1], linewidth=2, color=RGB(0,0,1)))
    end
    crop(img2, topleft, bottomright)
end

"""
    prep_img(path::String, ep::ExpPics; verbose=false)
    prep_img(img_color, ep; verbose=false)

Prepare image by:
- rotate and crop
- colordiff it
"""
function prep_img(path::String, ep::ExpPics; verbose=false)
    verbose && println(path)
    img_color = load(path);
    prep_img(img_color, ep; verbose=verbose)
end
function prep_img(img_color::AbstractArray, ep::ExpPics; verbose=false)
    @unpack p1, p2, halfheight, thin_num = ep
    img_color = rotate_n_crop(img_color, p1, p2, halfheight, verbose=verbose)
    img_color = thin(img_color, thin_num);
    @assert size(img_color)==ep.siz
    # calculate the difference in color
    img, loc = colordiffit(img_color, ep, verbose=verbose);
    return img, loc
end

"""
    colordiffit(img_color, ep::ExpPics; verbose=false)

Use `colordiff` make an image of perceived color difference
"""
function colordiffit(img_color, ep::ExpPics; verbose=false)
    loc = ep.color_loc
    c0 = img_color[loc...]
    if verbose
        guidict = imshow(img_color)
        dp = size(img_color,1)÷50
        annotate!(guidict, AnnotationBox(loc[2]+dp, loc[1]+dp, loc[2]-dp, loc[1]-dp, linewidth=2, color=RGB(0,0,1)))
    end
    colordiff.(img_color, c0), loc
end