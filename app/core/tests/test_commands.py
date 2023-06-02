"""
Test custom Django management commands.
We gonna mock the behavior of the database to validate if it
is responding or not.
"""

from unittest.mock import patch

from psycopg2 import OperationalError as Psycopg2Error

from django.core.management import call_command
from django.db.utils import OperationalError
from django.test import SimpleTestCase


# mock the behavior of the database
@patch('core.management.commands.wait_for_db.Command.check')
class CommandTests(SimpleTestCase):
    """Test commands."""

    def test_wait_for_db_ready(self, patched_check):
        """Test waiting for database if database is ready."""

        patched_check.return_value = True
        call_command('wait_for_db')
        # ensures that the 'check' value, the mocked object,
        # is called with these parameters.
        patched_check.assert_called_once_with(databases=['default'])

    # it will replace the 'time.sleep' built-in function,
    # so we are overriding the behavior of 'sleep' so it doesn't
    # pause actually pause our execution unit test.
    @patch('time.sleep')
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        """Test waiting for the database when getting OperationalError"""

        # When you're mocking objects, which in this case is
        # the 'check' object/method: you raise some Exceptions
        # by using the 'side_effect'
        # It allows you to pass in various different items that
        # get handled differently depending on that type.
        # So if we pass in an exception, then the mocking library
        # knows that, and it should raise that Exception.
        # Also, these are arbitrary values..
        patched_check.side_effect = [Psycopg2Error] * 2 + \
            [OperationalError] * 3 + [True]
        call_command('wait_for_db')
        self.assertEqual(patched_check.call_count, 6)
        patched_check.assert_called_with(databases=['default'])
