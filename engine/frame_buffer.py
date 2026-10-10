import queue
import threading
import time

class FrameBuffer:
    def __init__(self, capacity: int, sample_interval: int):
        self.capacity = capacity
        self.sample_interval = sample_interval
        self._queue = queue.Queue(maxsize=capacity)
        self._frame_count = 0
        self._stopped = False

    def put(self, frame_data: dict):
        if self._stopped:
            return
            
        self._frame_count += 1
        if self._frame_count % self.sample_interval != 0:
            return

        try:
            if self._queue.full():
                # Drop oldest
                try:
                    self._queue.get_nowait()
                except queue.Empty:
                    pass
            self._queue.put_nowait(frame_data)
        except queue.Full:
            pass

    def get(self, timeout: float = None):
        try:
            return self._queue.get(timeout=timeout)
        except queue.Empty:
            return None

    def stop(self):
        self._stopped = True
