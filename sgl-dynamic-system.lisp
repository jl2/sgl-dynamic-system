;; sgl-dynamic-system.lisp
;;
;; Copyright (c) 2021 Jeremiah LaRocco <jeremiah_larocco@fastmail.com>


;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.

;; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
;; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
;; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
;; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
;; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
;; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

(in-package :sgl-dynamic-system)

(setf sgl:*shader-dirs*
      (adjoin (asdf:system-relative-pathname :sgl-dynamic-system "shaders/") sgl:*shader-dirs*))


(defclass sgl-dynamic-system (instanced-opengl-object)
  ((primitive-type :initform :points)
   (width :initform 128 :initarg :width)
   (height :initform 128 :initarg :height)
   (depth :initform 1 :initarg :depth)
   (min-corner :initform (vec3 -1.0f0 -1.0f0 -1.0f0) :initarg :min-corner)
   (max-corner :initform (vec3 1.0f0 1.0f0 1.0f0) :initarg :max-corner)
   ))

(defmethod initialize-buffers ((object sgl-dynamic-system) &key)
  (when (buffers object)
    (error "Object buffers already setup!"))
  (with-slots (width height depth max-corner min-corner instance-count) object
    (let* ((step (v/ (v- max-corner
                         min-corner)
                    (vec3 (if (= width 1)
                              1
                              (1- width))
                          (if (= height 1)
                              1
                              (1- height))
                          (if (= depth 1)
                              1
                              (1- depth)))))
          (data (loop
                             for i below width
                             collecting
                             (loop
                               for j below height
                               collecting
                               (loop
                                 for k below depth
                                 for pt = (v+
                                           min-corner
                                           (vx_z (vec3-random -0.5 0.5))
                                           (v* (vec3 i j k) step))
                                 collecting pt
                                 collecting (let* ((r (+ 0.25 (* 0.5 (abs (cos (vx pt))))))
                                                   (g (+ 0.25 (* 0.75 (abs (cos (vy pt))))))
                                                   (b (+ 0.25 (* 0.5 (abs (cos (vz pt))))))
                                                   (alpha 0.125))
                                              (vec4 r g b alpha))))))
           (indices (loop for i below (* width height depth)
                          collecting i)))
      (set-buffer object
                :vertices
                (make-instance
                 'attribute-buffer
                 :pointer (to-gl-array
                           :float
                           (* 7 width height depth)
                           data)
                 :stride nil
                 :attributes '(("in_position" . :vec3) ("in_color" . :vec4))
                 :usage :static-draw
                 :free t))
      (set-buffer object
                  :indices
                  (make-instance
                   'index-buffer
                   :idx-count (* 1 width height depth)
                   :pointer (to-gl-array :unsigned-int
                                         (* 1 width height depth)
                                         indices)
                   :stride nil
                   :usage :static-draw
                   :free t))
      (set-buffer object
                  :obj-transform
                  (make-instance
                   'instance-buffer
                   :pointer (to-gl-array :float 16
                                         (meye 4))
                  :stride nil
                  :attributes '(("obj_transform" . :mat4))
                  :usage :static-draw
                   :free t))
      (setf instance-count 3))))

(defun create-dynamic-system (width height depth max-corner min-corner)
  (let ((dh 0.125)
        (obj (make-instance 'sgl-dynamic-system
                            :width width
                            :height height
                            :depth depth
                            :max-corner max-corner
                            :min-corner min-corner
                            :style (sgl:make-style "dynamic-system" "ds-vertex.glsl" "ds-fragment.glsl" "ds-geometry.glsl"))))
    (sgl:set-uniform obj "dh" dh :float)
    obj))