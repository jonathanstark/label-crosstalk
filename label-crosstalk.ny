;nyquist plug-in
;version 4
;type analyze
;name "Label Crosstalk..."
;author "Hobbes / JS"
;release 3.0.0
;copyright "Public Domain"

;; Label Crosstalk - Audacity 3.x Nyquist Plugin
;;
;; Select exactly 2 mono tracks (separate speaker tracks), then run
;; from the Analyze menu. Marks regions where both tracks have audio
;; energy simultaneously -- i.e., crosstalk / overlap.
;;
;; How it works: Nyquist processes selected tracks sequentially.
;; Pass 1 stores the first track's energy profile on *SCRATCH*.
;; Pass 2 computes the second track's profile, compares, and
;; returns labels marking overlap regions.

;control text "Audio quieter than this is treated as silence."
;control threshold "Silence threshold (dB)" float-text "dB" -40 -80 0
;control text "Overlaps shorter than this are ignored."
;control min-duration "Minimum overlap (ms)" float-text "ms" 750 0 5000
;control text "Size of each analysis chunk. Smaller = more precise but slower."
;control window-ms "Analysis window (ms)" float-text "ms" 50 10 500

;; Convert dB to linear
(defun db-to-lin (db)
  (power 10.0 (/ db 20.0)))

;; Compute energy profile as a list of 0/1 values (one per window).
(defun compute-energy-profile (snd thresh-lin win-samps step-samps)
  (let* ((peak-env (snd-avg (s-abs snd) win-samps step-samps OP-PEAK))
         (vals (snd-samples peak-env 10000000))
         (result nil))
    (dotimes (i (length vals))
      (push (if (>= (aref vals i) thresh-lin) 1 0) result))
    (reverse result)))

;; Find overlapping active regions between two boolean profiles.
(defun find-overlaps (prof-a prof-b step-sec min-dur-sec)
  (let ((labels nil)
        (in-overlap nil)
        (overlap-start 0.0)
        (len (min (length prof-a) (length prof-b))))
    (dotimes (i len)
      (let* ((a (nth i prof-a))
             (b (nth i prof-b))
             (t-sec (* i step-sec))
             (both (and (> a 0) (> b 0))))
        (cond
          ((and both (not in-overlap))
           (setf in-overlap t)
           (setf overlap-start t-sec))
          ((and (not both) in-overlap)
           (setf in-overlap nil)
           (when (>= (- t-sec overlap-start) min-dur-sec)
             (push (list overlap-start t-sec "Crosstalk") labels))))))
    (when in-overlap
      (let ((t-end (* len step-sec)))
        (when (>= (- t-end overlap-start) min-dur-sec)
          (push (list overlap-start t-end "Crosstalk") labels))))
    (reverse labels)))

;; ---- Main ----

;; Compute parameters
(setf thresh-lin (db-to-lin threshold))
(setf sr *sound-srate*)
(setf win-samps (max 1 (round (* (/ window-ms 1000.0) sr))))
(setf step-samps win-samps)
(setf step-sec (/ (float step-samps) sr))
(setf min-dur-sec (/ min-duration 1000.0))

;; Track count validation using *SELECTION* TRACKS property (Audacity 3.x).
(setf selected-tracks (get '*selection* 'tracks))
(setf num-selected (if selected-tracks (length selected-tracks) 0))

(cond
  ;; Wrong number of tracks
  ((/= num-selected 2)
   (remprop '*scratch* 'crosstalk-profile-a)
   (format nil
     "Select exactly 2 mono tracks, then run again.~%~
      Currently ~a track~a selected."
     num-selected
     (if (= num-selected 1) "" "s")))

  ;; Pass 1: first track -- store energy profile
  ((not (get '*scratch* 'crosstalk-profile-a))
   (let ((snd (if (arrayp *track*) (aref *track* 0) *track*)))
     (putprop '*scratch*
              (compute-energy-profile snd thresh-lin win-samps step-samps)
              'crosstalk-profile-a)
     ""))

  ;; Pass 2: second track -- compare and return labels
  (t
   (let* ((snd (if (arrayp *track*) (aref *track* 0) *track*))
          (prof-a (get '*scratch* 'crosstalk-profile-a))
          (prof-b (compute-energy-profile snd thresh-lin win-samps step-samps))
          (labels (find-overlaps prof-a prof-b step-sec min-dur-sec)))
     (remprop '*scratch* 'crosstalk-profile-a)
     (if labels
         labels
         "No crosstalk regions detected."))))
